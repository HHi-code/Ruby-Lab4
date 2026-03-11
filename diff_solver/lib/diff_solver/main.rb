require_relative 'expression'


expr = DiffSolver::Expression.new("x+2")
der = expr.derivative(:x)
puts der.string