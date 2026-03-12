require_relative 'expression'


puts "Добро пожаловать в программу символьного дифференцирования!"
puts

begin
  print "Введите математическое выражение (например, x+2): "
  expr_str = gets.chomp
  print "Введите переменную для дифференцирования (по умолчанию x): "
  var = gets.chomp
  var = 'x' if var.empty?
  expr = DiffSolver::Expression.new(expr_str)
  derivative = expr.derivative(var)

  puts "Производная: #{derivative.string}"

rescue DiffSolver::Error => e
  puts "Ошибка: #{e.message}"
rescue StandardError => e
  puts "Неожиданная ошибка: #{e.message}"
end