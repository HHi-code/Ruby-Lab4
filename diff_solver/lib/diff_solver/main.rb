require_relative 'expression'


expr = DiffSolver::Expression.new("2x")
der = expr.derivative(:x)
puts der.string