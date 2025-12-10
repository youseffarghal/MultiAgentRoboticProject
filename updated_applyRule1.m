function [A, nodes] = updated_applyRule1(A, nodes, leader_indices)
% applyRule1  Henneberg I move preferentially on leader triangle edges
%
%   A, nodes         : current adjacency matrix and node list
%   leader_indices   : 1x3 or 3x1 vector of leader node indices (triangle)

    N = size(A, 1);

    % ----- 1. Find all unused nodes (circle nodes) -----
    circleNodeIndexes = [];
    for i = 1:N
        if isequal(nodes{i}.shape, 'o')
            circleNodeIndexes = [circleNodeIndexes; i];
        end
    end

    % Choose a random unused node
    if isempty(circleNodeIndexes)
        return; % no available node to add
    end
    newNodeIndex = circleNodeIndexes(randi(length(circleNodeIndexes)));

    % ----- 2. Build preferred edge list: edges inside leader triangle -----
    edges = [];
    
    %Finds edges between leaders
    leader_indices = leader_indices(:)';  % force row vector
    if numel(leader_indices) == 3
        for p = 1:3
            for q = p+1:3
                i = leader_indices(p);
                j = leader_indices(q);
                if A(i,j) ~= 0
                    edges = [edges; i, j];
                end
            end
        end
    end

    % ----- 3. Fallback: if no leader edges exist, use any edge -----
    if isempty(edges)
        for i = 1:N
            for j = i+1:N
                if A(i,j) ~= 0
                    edges = [edges; i, j];
                end
            end
        end
    end

    % If still no edges, we cannot apply H1
    if isempty(edges)
        return;
    end

    % ----- 4. Choose a random edge and connect new node -----
    idx = randi(size(edges, 1));
    e = edges(idx, :);
    a = e(1);
    b = e(2);

    % Add edges (new node to a and b), undirected
    A(newNodeIndex, a) = 1;  A(a, newNodeIndex) = 1;
    A(newNodeIndex, b) = 1;  A(b, newNodeIndex) = 1;

    % Mark new node as used (square). You can keep it blue or change color if you like.
    nodes{newNodeIndex}.shape = 's';
    % Optionally: nodes{newNodeIndex}.color = [0 0 1];  % blue square
end
