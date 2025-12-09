function [ux_i, uy_i, pos_j_used] = fault_models(fault_type, pos_j)
% Handles non-compliant, malicious, and byzantine behavior
%
% Inputs:
%   fault_type        = 'none', 'non-compliant', 'malicious', 'byzantine'
%   pos_j             = true neighbor position (2x1)
%   ux_i, uy_i        = current control input for agent i
%   malicious_offset  = constant vector [dx dy]'
%   noise_scale       = scale factor for random noise

malicious_offset = [.1; 0]; ;
noise_scale = .1;

switch fault_type
    case "non-compliant"
        % Completely ignores controller
        ux_i = 0;
        uy_i = 0;
        pos_j_used = pos_j;    % no change in measurement for neighbors
        
    case "malicious"
        % Sends a constant incorrect measurement
        ux_i = 1; %Not actually used but set for function consistency
        uy_i = 1; %Not actually used but set for function consistency
        
        pos_j_used = pos_j + malicious_offset;
        
    case "byzantine"
        % Sends a random incorrect measurement each time
        ux_i = 1; %Not actually used but set for function consistency
        uy_i = 1; %Not actually used but set for function consistency

        pos_j_used = pos_j + noise_scale * randn(2,1);
        
    otherwise
        % healthy agent
        pos_j_used = pos_j;
end
end
