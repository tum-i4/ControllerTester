function output = CT_RegressionPoly3(b, input)
    % poly3
    N = size(input,1);
    output = zeros(N,1);
    for i = 1:N
        output(i) = b(1) + b(2)*input(i,1) + b(3)*input(i,2) +  b(4)*input(i,1)*input(i,2) + + b(5)*input(i,1)^2 + b(6)*input(i,2)^2 + b(7)*input(i,1)^2*input(i,2) + b(8)*input(i,1)*input(i,2)^2 + b(9)*input(i,1)^3 + b(10)*input(i,2)^3;
    end
end