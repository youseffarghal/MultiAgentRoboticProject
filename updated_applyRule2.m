function [A, nodes] = updated_applyRule2(A, nodes, leader_indices)
% applyRule2  Henneberg II move (edge division) that NEVER divides
%             an edge of the original leader triangle.
%
%   A, nodes         : current adjacency matrix and node list
%   leader_indices   : 3-element vector of the original triangle nodes

    N = size(A,1);

    % ----- 1. Find all unused nodes (circle nodes) -----
    circleNodeIndexes = [];
    for i = 1:N
        if isequal(nodes{i}.shape, 'o')
            circleNodeIndexes = [circleNodeIndexes; i];
        end
    end

    % Choose 1 random unused node
    if isempty(circleNodeIndexes)
        return; % Exit if no circle nodes are found
    end
    newNodeIndex = circleNodeIndexes(randi(length(circleNodeIndexes)));

    % ----- 2. Build list of edges, EXCLUDING leader triangle edges -----
    edges = []; % Initialize empty list
    leader_indices = leader_indices(:)';  % ensure row vector

    for i = 1:N
        for j = i+1:N  % check only upper triangle
            if A(i,j) ~= 0
                % Skip edges whose BOTH endpoints are in the leader set
                if ismember(i, leader_indices) && ismember(j, leader_indices)
                    continue;  % do NOT allow dividing original triangle edges
                end
                edges = [edges; i, j];
            end
        end
    end

    % If there are no eligible edges, cannot apply H2
    if isempty(edges)
        return;
    end

    % ----- 3. Choose a random eligible edge (a,b) -----
    idx = randi(size(edges,1));
    e = edges(idx, :);
    a = e(1);
    b = e(2);

    % ----- 4. Find possible nodes C that have a path from a or b -----
    neighborsA = find(A(a,:) == 1);
    neighborsB = find(A(b,:) == 1);
    possibleC = unique([neighborsA neighborsB]);

    % Expand possibleC to include neighbors of neighbors (same component)
    while true
        [~, cCols] = find(A(possibleC, :) == 1);  % cCols: column indices in A
        newNeighbors = unique(cCols);
        newNeighbors = setdiff(newNeighbors, possibleC); % exclude already included
        if isempty(newNeighbors)
            break;
        end
        possibleC = unique([possibleC(:); newNeighbors(:)]);
    end

    % Remove a and b from candidate C list
    possibleC(possibleC == a | possibleC == b) = [];

    % If no valid c, we can't apply H2 with this edge
    if isempty(possibleC)
        return;
    end

    % Pick a random c
    c = possibleC(randi(length(possibleC)));

    % ----- 5. Remove old edge (a,b) and add H2 edges -----
    A(a,b) = 0;  A(b,a) = 0;

    % New node connects to a, b, and c
    A(newNodeIndex, a) = 1;  A(a, newNodeIndex) = 1;
    A(newNodeIndex, b) = 1;  A(b, newNodeIndex) = 1;
    A(newNodeIndex, c) = 1;  A(c, newNodeIndex) = 1;

    nodes{newNodeIndex}.shape = 's';
end
