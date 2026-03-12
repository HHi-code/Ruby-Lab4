# test/diff_solver_test.rb
# frozen_string_literal: true

require "test_helper"

class DiffSolverTest < Minitest::Test
  
  
  # константы
  def test_derivative_of_constant
    expr1 = DiffSolver::Expression.new("5")
    assert_equal "0", expr1.derivative("x").string
    
    expr2 = DiffSolver::Expression.new("-3")
    assert_equal "0", expr2.derivative("x").string
  end

  # переменные 
  def test_derivative_of_variable_1
    expr1 = DiffSolver::Expression.new("x")
    assert_equal "1", expr1.derivative("x").string
    
    expr2 = DiffSolver::Expression.new("y")
    assert_equal "1", expr2.derivative("y").string
  end

  # другой аргумент
  def test_derivative_of_other_arg
    expr1 = DiffSolver::Expression.new("y")
    assert_equal "0", expr1.derivative("x").string
    
    expr2 = DiffSolver::Expression.new("z")
    assert_equal "0", expr2.derivative("x").string
  end

  # сложение
  def test_addition_1
    expr1 = DiffSolver::Expression.new("x + 5")
    assert_equal "1", expr1.derivative("x").string
    
    expr2 = DiffSolver::Expression.new("x + y")
    assert_equal "1", expr2.derivative("x").string
  end

  # сложение аргументов
  def test_addition_2
    expr1 = DiffSolver::Expression.new("x + x")
    result1 = expr1.derivative("x").string
    assert_match(/1.*\+.*1|2/, result1)
    
    expr2 = DiffSolver::Expression.new("x + 2 * x")
    result2 = expr2.derivative("x").string
    assert_match(/1.*\+.*2|2.*\+.*1|3/, result2)
  end

  # вычитание
  def test_subtraction
    expr1 = DiffSolver::Expression.new("x - 3")
    assert_equal "1", expr1.derivative("x").string
    
    expr2 = DiffSolver::Expression.new("x - y")
    assert_equal "1", expr2.derivative("x").string
  end

  # умножение на консанту
  def test_multiplication_on_constant_1
    expr1 = DiffSolver::Expression.new("2 * x")
    assert_equal "2", expr1.derivative("x").string
    
    expr2 = DiffSolver::Expression.new("5 * x")
    assert_equal "5", expr2.derivative("x").string
  end

  def test_multiplication_on_constant_2
    expr1 = DiffSolver::Expression.new("x * 3")
    assert_equal "3", expr1.derivative("x").string
    
    expr2 = DiffSolver::Expression.new("x * 10")
    assert_equal "10", expr2.derivative("x").string
  end

  # умножение переменных
  def test_multiplication
    expr1 = DiffSolver::Expression.new("x * x")
    result1 = expr1.derivative("x").string
    assert_match(/2.*\*.*x|x.*\*.*2|(\(x\+\))|(\+.*x)/, result1)
    
    expr2 = DiffSolver::Expression.new("x * y")
    result2 = expr2.derivative("x").string
    assert_match(/y/, result2)
  end

  # степень  
  def test_power
    expr1 = DiffSolver::Expression.new("x^2")
    result1 = expr1.derivative("x").string
    assert_match(/2.*\*.*x|x.*\*.*2/, result1)
    
    expr2 = DiffSolver::Expression.new("x^3")
    result2 = expr2.derivative("x").string
    assert_match(/3/, result2)
    assert_match(/\^.*2/, result2)
  end

  def test_power_with_coefficient
    expr1 = DiffSolver::Expression.new("3 * x^2")
    result1 = expr1.derivative("x").string
    assert_match(/6.*\*.*x|x.*\*.*6/, result1)
    
    expr2 = DiffSolver::Expression.new("2 * x^3")
    result2 = expr2.derivative("x").string
    assert_match(/6/, result2)  
    assert_match(/\^.*2/, result2)
  end

  # деление
  def test_division_by_constant
    expr1 = DiffSolver::Expression.new("x / 2")
    result1 = expr1.derivative("x").string
    assert_match(/0\.5|1\/2/, result1)
    
    expr2 = DiffSolver::Expression.new("x / 4")
    result2 = expr2.derivative("x").string
    assert_match(/0\.25|1\/4/, result2)
  end

  # sin
  def test_sin
    expr1 = DiffSolver::Expression.new("sin(x)")
    result1 = expr1.derivative("x").string
    assert_match(/cos/, result1)
    
    expr2 = DiffSolver::Expression.new("sin(2x)")
    result2 = expr2.derivative("x").string
    assert_match(/cos/, result2)
    assert_match(/2/, result2)
  end

  # cos
  def test_cos
    expr1 = DiffSolver::Expression.new("cos(x)")
    result1 = expr1.derivative("x").string
    assert_match(/sin/, result1)
    
    expr2 = DiffSolver::Expression.new("cos(3x)")
    result2 = expr2.derivative("x").string
    assert_match(/sin/, result2)
    assert_match(/3/, result2)
  end
  # log
  def test_log
    expr1 = DiffSolver::Expression.new("log(x)")
    result1 = expr1.derivative("x").string
    assert_match(/1.*\/.*x/, result1)
  end

  # exp
  def test_exp
    expr1 = DiffSolver::Expression.new("exp(x)")
    result1 = expr1.derivative("x").string
    assert_match(/exp/, result1)
    
    expr2 = DiffSolver::Expression.new("exp(2x)")
    result2 = expr2.derivative("x").string
    assert_match(/exp/, result2)
    assert_match(/2/, result2)
  end

  # умножение 2x, 2(x+1) ...
  def test_implicit_multiplication_1
    expr1 = DiffSolver::Expression.new("2x")
    assert_equal "2", expr1.derivative("x").string
    
    expr2 = DiffSolver::Expression.new("5x")
    assert_equal "5", expr2.derivative("x").string
  end

  def test_implicit_multiplication_2
    expr1 = DiffSolver::Expression.new("2(x + 1)")
    result1 = expr1.derivative("x").string
    assert_match(/2/, result1)
    
    expr2 = DiffSolver::Expression.new("3(x^2)")
    result2 = expr2.derivative("x").string
    assert_match(/6.*\*.*x|x.*\*.*6/, result2)
  end

  # формулы  
  def test_formulas
    expr1 = DiffSolver::Expression.new("x^2 + 3 * x + 1")
    result1 = expr1.derivative("x").string
    assert_match(/2/, result1)  
    assert_match(/3/, result1)  
    
    expr2 = DiffSolver::Expression.new("2 * x^2 + 5 * x")
    result2 = expr2.derivative("x").string
    assert_match(/4.*\*.*x|x.*\*.*4/, result2)  
    assert_match(/5/, result2)
  end

  def test_trig_sum
    expr1 = DiffSolver::Expression.new("sin(x) + cos(x)")
    result1 = expr1.derivative("x").string
    assert_match(/cos/, result1)
    assert_match(/sin/, result1)
    
    expr2 = DiffSolver::Expression.new("sin(x) + x^2")
    result2 = expr2.derivative("x").string
    assert_match(/cos/, result2)
    assert_match(/2.*\*.*x|x.*\*.*2/, result2)
  end


  # проверка на дифференцирование аргумента
  def test_chain_rule
    expr1 = DiffSolver::Expression.new("exp(x^2)")
    result1 = expr1.derivative("x").string
    assert_match(/exp/, result1)
    assert_match(/x/, result1)
    
    expr2 = DiffSolver::Expression.new("log(3x)")
    result2 = expr2.derivative("x").string
    assert_match(/1.*\/.*3.*\*.*x|3.*\*.*x/, result2)
  end
  
  def test_invalid_expression_raises
    # невалидное выражение
    assert_raises DiffSolver::Error do
      DiffSolver::Expression.new("invalid @@ expr")
    end
    
    # пустая строка
    assert_raises DiffSolver::Error do
      DiffSolver::Expression.new("")
    end
  end

  def test_unknown_function_raises
    # неизвестная функция
    assert_raises DiffSolver::Error do
      expr = DiffSolver::Expression.new("unknown_func(x)")
      expr.derivative("x")
    end
    
    # другая неизвестная функция
    assert_raises DiffSolver::Error do
      expr = DiffSolver::Expression.new("sec(x)")  
    end
  end

  # x и y 
  def test_variable_multiplication
    expr = DiffSolver::Expression.new("x * y * z")
    result = expr.derivative("x").string
    assert_match(/y\s*\*\s*z|z\s*\*\s*y/, result)
    refute_match(/x/, result)
    end
  end

  def test_variable_division
  expr = DiffSolver::Expression.new("x / y")
  result = expr.derivative("x").string
  assert_match(/1\s*\/\s*y/, result)
  result_y = expr.derivative("y").string
  assert_match(/-.*x.*\/.*y\^2|-x\/y\^2/, result_y)
end