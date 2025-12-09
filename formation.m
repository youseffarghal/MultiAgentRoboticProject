function [A, nodes] = formation(A, nodes, D, params, ax_plotsol)
% DISTANCE-BASED FORMATION CONTROL (gradient descent)
% A      : adjacency matrix (NxN)
% nodes  : cell array of NodeObj with fields .x, .y
% D      : desired distance matrix (NxN), nonzero for edges
% params : struct with fields dt, k, max_iters, plot_every
% ax_plotsol : (optional) axis handle for plotsol map visualization
%
% Returns updated A (unchanged) and nodes with updated positions.

if nargin < 4 || isempty(params)
    params.dt = 0.05;
    params.k = 1.0;
    params.max_iters = 1000;
    params.plot_every = 10;
end

FAULT_TYPES = ['none', 'non-compliant', "pulsing", 'malicious', 'byzantine'];
FAULT_TYPE = 1;
faulty_nodes = [];

leaders = [1, 3, 5];

N = size(A,1); % number of agents

% Extract initial positions from nodes
px = zeros(N,1);
py = zeros(N,1);
for i = 1:N
    px(i) = nodes{i}.x;
    py(i) = nodes{i}.y;
end

for iter = 1:params.max_iters

    % Initialize velocity vectors
    ux = zeros(N,1);
    uy = zeros(N,1);
    
    % -------- Rigid-body trajectory (translation + rotation) --------
    phase_iters = params.max_iters / 3;
    
    if iter < phase_iters 
        % Phase 1: Move right
        vel_x = .15;
        vel_y = 0;
        omega = 0;
    elseif iter < 2 * phase_iters
        % Phase 2: Rotate clockwise
        vel_x = 0;
        vel_y = 0;
        omega = -0.05;
    else
        % Phase 3: Move down
        vel_x = 0;
        vel_y = -0.15;
        omega = 0;
    end
    
    % Centroid for rotation
    cx = mean(px);
    cy = mean(py);
    
    % -------- Formation control + group motion --------
    for i = 1:N

        if ismember(i, faulty_nodes) && FAULT_TYPES(FAULT_TYPE) == "non-compliant"
            [ux(i), uy(i), ~] = fault_models(FAULT_TYPES(FAULT_TYPE), [px(i); py(i)]);
            continue;
        end

        neighbors = find(A(i,:) == 1);
        pos_i = [px(i); py(i)];
        
        for j = neighbors
            pos_j = [px(j); py(j)];

            if ismember(j, faulty_nodes) && (FAULT_TYPES(FAULT_TYPE) == "malicious" || FAULT_TYPES(FAULT_TYPE) == "byzantine")
                [~, ~, pos_j] = fault_models(FAULT_TYPES(FAULT_TYPE), pos_j);
            end

            rij = pos_i - pos_j;
            dist2 = rij' * rij;
            desired2 = D(i,j)^2;
            
            err = dist2 - desired2;
            
            % Gradient of 0.25*(dist2 - desired2)^2 wrt p_i
            grad = err * rij;
            
            ux(i) = ux(i) - params.k * grad(1);
            uy(i) = uy(i) - params.k * grad(2);
        end
        
        % --- leader input only for node 1 ---
        if ismember(i, leaders)
            % translation
            ux(i) = ux(i) + vel_x;
            uy(i) = uy(i) + vel_y;

            % (optional) rotation about centroid – also only applied to node 1
            rx = px(i) - cx;
            ry = py(i) - cy;
            ux(i) = ux(i) - omega * ry;
            uy(i) = uy(i) + omega * rx;
        end
    end

    % Euler update
    px = px + params.dt * ux;
    py = py + params.dt * uy;

    % update nodes object
    for i = 1:N
        nodes{i}.x = px(i);
        nodes{i}.y = py(i);
    end

    if mod(iter, params.plot_every) == 0
        cla(ax_plotsol);
        hold(ax_plotsol, 'on');

        X_current = zeros(2, N);
        for i = 1:N
            X_current(1,i) = nodes{i}.x;
            X_current(2,i) = nodes{i}.y;
        end

        for i = 1:N
            if ismember(i, leaders)
                % Leader = green
                    plot(ax_plotsol, X_current(1,i), X_current(2,i), 'o', ...
                        'MarkerSize', 10, 'MarkerFaceColor', 'green', 'MarkerEdgeColor', 'k');
            elseif ismember(i, faulty_nodes)
                % Faulty = red
                    plot(ax_plotsol, X_current(1,i), X_current(2,i), 'o', ...
                        'MarkerSize', 9, 'MarkerFaceColor', 'red', 'MarkerEdgeColor', 'k');
            else
                % Followers = blue
                    plot(ax_plotsol, X_current(1,i), X_current(2,i), 'o', ...
                        'MarkerSize', 8, 'MarkerFaceColor', 'blue', 'MarkerEdgeColor', 'k');
            end

            %Draw edges
            for j = i+1:N
                if A(i,j) == 1
                    plot(ax_plotsol, [X_current(1,i), X_current(1,j)], ...
                                    [X_current(2,i), X_current(2,j)], ...
                                    'k-', 'LineWidth', 1.5);
                end
            end
        end

    grid(ax_plotsol, 'on');
    axis(ax_plotsol, 'equal');

    % --- Dynamic axis tracking ---
    cx_plot = mean(X_current(1,:));
    cy_plot = mean(X_current(2,:));

    r = max(sqrt((X_current(1,:) - cx_plot).^2 + ...
             (X_current(2,:) - cy_plot).^2));
    if r <= 0 || ~isfinite(r)
    r = 1;
    end

    margin = 1.8;
    axis(ax_plotsol, [cx_plot - margin*r, cx_plot + margin*r, ...
                    cy_plot - margin*r, cy_plot + margin*r]);

    title(ax_plotsol, sprintf('Formation Control - Iteration %d', iter));
    drawnow;
    end
end
end
