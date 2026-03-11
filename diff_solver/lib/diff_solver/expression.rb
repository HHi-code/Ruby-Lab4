require "dentaku"


module DiffSolver
    class Error < StandardError; end
    class Expression
        attr_reader :string,:ast 

        def initialize(string)
            @string = string
            lexer = Dentaku::Tokenizer.new
            tokens = lexer.tokenize(string)
            @parser = Dentaku::Parser.new(tokens)
            @ast = @parser.parse
            raise Error, "Invalid expression: #{string}" unless @ast
        end

        def derivative(var)
            new_ast = differentiate(@ast, var.to_s)
            simplified_ast = simplify(new_ast) 
            self.class.from_ast(simplified_ast)
        end
        def self.from_ast(ast)
            new(unparse(ast))
        end
        def numeric_node(value)
            token = Dentaku::Token.new(:numeric, value)
            Dentaku::AST::Numeric.new(token)
        end

        def differentiate(ast,var)
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
            when Dentaku::AST::Grouping
                differentiate(ast.inner,var)
            else
                raise Error, "Unknown node type: #{ast.class}"
            end
        end

        def self.unparse(node)
             puts "unparse called for #{node.class}"
            case node
            when Dentaku::AST::Numeric
                    node.to_s
            when Dentaku::AST::Identifier
                    node.to_s
            when Dentaku::AST::Addition
                "(#{unparse(node.left)} + #{unparse(node.right)})"
            when Dentaku::AST::Subtraction
                "(#{unparse(node.left)} - #{unparse(node.right)})"
            when Dentaku::AST::Multiplication
                "(#{unparse(node.left)} * #{unparse(node.right)})"
            when Dentaku::AST::Division
                "(#{unparse(node.left)} / #{unparse(node.right)})"
            when Dentaku::AST::Exponentiation
                "(#{unparse(node.left)} ^ #{unparse(node.right)})"
            when Dentaku::AST::Function
                "#{node.identifier}(#{node.args.map { |arg| unparse(arg) }.join(', ')})"
            when Dentaku::AST::Grouping
                "(#{unparse(node.inner)})"
            else
                node.to_s
            end
        end
        def numeric_value(node)
            node.is_a?(Dentaku::AST::Numeric) ? node.instance_variable_get(:@value) : nil
        end
        def simplify(node)
            case node
            when Dentaku::AST::Numeric, Dentaku::AST::Identifier
                node 

            when Dentaku::AST::Grouping
                inner = simplify(node.inner)
                if inner.is_a?(Dentaku::AST::Numeric) || inner.is_a?(Dentaku::AST::Identifier)
                    inner
                else
                    Dentaku::AST::Grouping.new(inner)
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
                    make_numeric(left_num + right_num)
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
                make_numeric(left_num - right_num)
            else
                Dentaku::AST::Subtraction.new(left, right)
            end

            when Dentaku::AST::Multiplication
                left = simplify(node.left)
                right = simplify(node.right)
                left_num = numeric_value(left)
                right_num = numeric_value(right)

                if (left_num == 0) || (right_num == 0)
                    make_numeric(0)
                elsif left_num == 1
                    right
                elsif right_num == 1
                    left
                elsif left_num && right_num
                    make_numeric(left_num * right_num)
                else
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
                    make_numeric(0)
                elsif left_num && right_num && right_num != 0
                    make_numeric(left_num / right_num.to_f) # используем float для деления
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
                    make_numeric(1)
                elsif left_num && right_num
                    make_numeric(left_num ** right_num)
                else
                    Dentaku::AST::Exponentiation.new(left, right)
            end

            when Dentaku::AST::Function
                simplified_args = node.args.map { |arg| simplify(arg) }
                Dentaku::AST::Function.new(node.identifier, simplified_args)
                else
                node
            end
        end


























    end
end  