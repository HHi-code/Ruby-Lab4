require "bundler/setup"
Bundler.require(:default)

module DiffSolver
    class Error < StandardError; end
    
    class Expression
        attr_reader :string, :ast 

        def initialize(string)
            @string = string
            
            raise Error, "Invalid expression: #{string}" if string.nil? || string.strip.empty?
            
            begin
                processed_string = string.gsub(/(\d)([a-zA-Z])/, '\1 * \2')  
                                       .gsub(/(\d)(\()/, '\1 * \2')         
                                       .gsub(/(\))(\d|[a-zA-Z])/, '\1 * \2')
                
                calculator = Dentaku::Calculator.new
                @ast = calculator.ast(processed_string)
                
                raise Error, "Invalid expression: #{string}" unless @ast
            rescue Dentaku::TokenizerError, Dentaku::ParseError => e
                raise Error, e.message
            rescue ArgumentError => e
                raise Error, "Invalid expression: #{string}"
            end
        end

        def derivative(var)
            new_ast = differentiate(@ast, var.to_s)
            simplified_ast = simplify(new_ast) 
            self.class.from_ast(simplified_ast)
        end
        
        def self.from_ast(ast)
            new(unparse(ast))
        end
        
        def differentiate(ast, var)
            case ast 
            when Dentaku::AST::Numeric
                numeric_node(0)
            when Dentaku::AST::Identifier
                ast.identifier == var ? numeric_node(1) : numeric_node(0)
            when Dentaku::AST::Addition
                left = differentiate(ast.left, var)
                right = differentiate(ast.right, var)
                Dentaku::AST::Addition.new(left, right)
            when Dentaku::AST::Subtraction
                left = differentiate(ast.left, var)
                right = differentiate(ast.right, var)
                Dentaku::AST::Subtraction.new(left, right)
            when Dentaku::AST::Negation
                inner_node = ast.respond_to?(:expression) ? ast.expression : ast.value
                if inner_node.is_a?(Dentaku::AST::Numeric) || inner_node.is_a?(Integer) || inner_node.is_a?(Numeric)
                    numeric_node(0)
                else
                    inner = differentiate(inner_node, var)
                    Dentaku::AST::Multiplication.new(numeric_node(-1), inner)
                end
            when Dentaku::AST::Grouping
                differentiate(ast.inner, var)
            when Dentaku::AST::Multiplication
                left = ast.left
                right = ast.right
                left_deriv = differentiate(left, var)
                right_deriv = differentiate(right, var)
                term1 = Dentaku::AST::Multiplication.new(left_deriv, right)
                term2 = Dentaku::AST::Multiplication.new(left, right_deriv)
                Dentaku::AST::Addition.new(term1, term2)
            when Dentaku::AST::Division
                left = ast.left
                right = ast.right
                left_deriv = differentiate(left, var)
                right_deriv = differentiate(right, var)
                left_mult_deriv = Dentaku::AST::Multiplication.new(left_deriv, right)
                right_mult_deriv = Dentaku::AST::Multiplication.new(left, right_deriv)
                substraction_deriv = Dentaku::AST::Subtraction.new(left_mult_deriv, right_mult_deriv)
                power_deriv = Dentaku::AST::Exponentiation.new(right, numeric_node(2))
                Dentaku::AST::Division.new(substraction_deriv, power_deriv)
            when Dentaku::AST::Exponentiation 
                base = ast.left
                exp = ast.right
                base_deriv = differentiate(base, var)
                new_exp = Dentaku::AST::Subtraction.new(exp, numeric_node(1))
                power_term = Dentaku::AST::Exponentiation.new(base, new_exp)
                mult1 = Dentaku::AST::Multiplication.new(exp, power_term)
                Dentaku::AST::Multiplication.new(mult1, base_deriv)
            when Dentaku::AST::Function
                func_name = ast.name.to_s.downcase
                arg = ast.args.first
                arg_deriv = differentiate(arg, var)
                case func_name
                when 'sin'
                    out_deriv = parse_function('cos', arg)
                    Dentaku::AST::Multiplication.new(out_deriv, arg_deriv)
                when 'cos'
                    out_deriv = parse_function('sin', arg)
                    negative = Dentaku::AST::Multiplication.new(numeric_node(-1), out_deriv)
                    Dentaku::AST::Multiplication.new(negative, arg_deriv)
                when 'log', 'ln'
                    div = Dentaku::AST::Division.new(numeric_node(1), arg)
                    Dentaku::AST::Multiplication.new(div, arg_deriv)
                when 'exp'
                    out_deriv = parse_function('exp', arg)
                    Dentaku::AST::Multiplication.new(out_deriv, arg_deriv)
                else
                    raise Error, "Неизвестная функция: #{func_name}"
                end
            else
                raise Error, "Неизвестный тип: #{ast.class}"
            end
        end

        def parse_function(name, arg_node)
            arg_string = self.class.unparse(arg_node)
            expr_string = "#{name}(#{arg_string})"
            calculator = Dentaku::Calculator.new
            calculator.ast(expr_string)
        end

        def self.unparse(node)
            case node
            when Dentaku::AST::Numeric
                val = node.value
                val == val.to_i ? val.to_i.to_s : val.to_s
            when Dentaku::AST::Identifier
                node.identifier.to_s
            when Dentaku::AST::Addition
                "#{unparse(node.left)} + #{unparse(node.right)}"
            when Dentaku::AST::Subtraction
                "#{unparse(node.left)} - #{unparse(node.right)}"
            when Dentaku::AST::Multiplication
                "#{unparse(node.left)} * #{unparse(node.right)}"
            when Dentaku::AST::Division
                "#{unparse(node.left)} / #{unparse(node.right)}"
            when Dentaku::AST::Exponentiation
                "#{unparse(node.left)}^#{unparse(node.right)}"
            when Dentaku::AST::Function
                # Конвертируем имя функции в нижний регистр
                "#{node.name.to_s.downcase}(#{node.args.map { |arg| unparse(arg) }.join(', ')})"
            when Dentaku::AST::Grouping
                unparse(node.inner)
            when Dentaku::AST::Negation
                inner = node.respond_to?(:expression) ? node.expression : node.value
                if inner.is_a?(Dentaku::AST::Numeric)
                    val = inner.value
                    val == val.to_i ? (-val.to_i).to_s : (-val).to_s
                else
                    "-#{unparse(inner)}"
                end
            else
                node.to_s
            end
        end
        
        def numeric_value(node)
            return nil unless node.is_a?(Dentaku::AST::Numeric)
            node.value
        end
        
        def simplify(node)
            case node
            when Dentaku::AST::Numeric, Dentaku::AST::Identifier
                node 
            when Dentaku::AST::Grouping
                simplify(node.inner)
            when Dentaku::AST::Negation
                inner_node = node.respond_to?(:expression) ? node.expression : node.value
                if inner_node.is_a?(Dentaku::AST::Numeric)
                    numeric_node(-inner_node.value)
                else
                    inner = simplify(inner_node)
                    inner_num = numeric_value(inner)
                    if inner_num
                        numeric_node(-inner_num)
                    else
                        Dentaku::AST::Multiplication.new(numeric_node(-1), inner)
                    end
                end
            when Dentaku::AST::Addition
                left = simplify(node.left)
                right = simplify(node.right)
                left_num = numeric_value(left)
                right_num = numeric_value(right)

                if left_num == 0
                    right
                elsif right_num == 0
                    left
                elsif left_num && right_num
                    numeric_node(left_num + right_num)
                else
                    Dentaku::AST::Addition.new(left, right)
                end
            when Dentaku::AST::Subtraction
                left = simplify(node.left)
                right = simplify(node.right)
                left_num = numeric_value(left)
                right_num = numeric_value(right)

                if right_num == 0
                    left
                elsif left_num && right_num
                    numeric_node(left_num - right_num)
                else
                    Dentaku::AST::Subtraction.new(left, right)
                end
            when Dentaku::AST::Multiplication
                left = simplify(node.left)
                right = simplify(node.right)
                left_num = numeric_value(left)
                right_num = numeric_value(right)

                if (left_num == 0) || (right_num == 0)
                    numeric_node(0)
                elsif left_num == 1
                    right
                elsif right_num == 1
                    left
                elsif left_num && right_num
                    numeric_node(left_num * right_num)
                else
                    if left.is_a?(Dentaku::AST::Multiplication)
                        left_left = left.left
                        left_right = left.right
                        left_left_num = numeric_value(left_left)
                        if left_left_num && right_num
                            new_num = numeric_node(left_left_num * right_num)
                            return Dentaku::AST::Multiplication.new(new_num, left_right)
                        end
                    end
                    if right.is_a?(Dentaku::AST::Multiplication)
                        right_left = right.left
                        right_right = right.right
                        right_left_num = numeric_value(right_left)
                        if right_left_num && left_num
                            new_num = numeric_node(left_num * right_left_num)
                            return Dentaku::AST::Multiplication.new(new_num, right_right)
                        end
                    end
                    Dentaku::AST::Multiplication.new(left, right)
                end
            when Dentaku::AST::Division
                left = simplify(node.left)
                right = simplify(node.right)
                left_num = numeric_value(left)
                right_num = numeric_value(right)

                if right_num == 1
                    left
                elsif left_num == 0 && right_num != 0
                    numeric_node(0)
                elsif left_num && right_num && right_num != 0
                    result = left_num / right_num.to_f
                    if result == result.to_i
                        numeric_node(result.to_i)
                    else
                        numeric_node(result)
                    end
                else
                    Dentaku::AST::Division.new(left, right)
                end
            when Dentaku::AST::Exponentiation 
                left = simplify(node.left)
                right = simplify(node.right)
                left_num = numeric_value(left)
                right_num = numeric_value(right)

                if right_num == 1
                    left
                elsif right_num == 0
                    numeric_node(1)
                elsif left_num && right_num
                    numeric_node(left_num ** right_num)
                else
                    Dentaku::AST::Exponentiation.new(left, right)
                end
            when Dentaku::AST::Function
                simplified_args = node.args.map { |arg| simplify(arg) }
                parse_function(node.name.to_s, simplified_args.first)
            else
                node
            end
        end
        
        def numeric_node(value)
            token = Dentaku::Token.new(:numeric, value)
            Dentaku::AST::Numeric.new(token)
        end
    end
end