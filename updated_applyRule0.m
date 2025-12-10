function [A, nodes] = updated_applyRule0(leader_indices, A, nodes)
% applyRule0  Initialize graph with 3 leader nodes forming a triangle
%
%   leader_indices: vector of 3 distinct node indices, e.g. [1 2 3]

    % Reset adjacency matrix
    A(:,:) = 0;

    % Basic checks (optional but helpful)
    leader_indices = leader_indices(:)';   % force row vector
    if numel(leader_indices) ~= 3
        error('applyRule0: leader_indices must contain exactly 3 node indices.');
    end
    if numel(unique(leader_indices)) ~= 3
        error('applyRule0: leader_indices must be 3 distinct nodes.');
    end

    % Reset all nodes to isolated, default shape 'o' and blue color
    N = size(A,1);
    for i = 1:N
        % If nodes{i} is a handle object, this is enough:
        nodes{i}.shape = 'o';
        nodes{i}.color = [0 0 1];

        % If nodes{i} is a struct instead, use:
        % node = nodes{i};
        % node.shape = 'o';
        % node.color = [0 0 1];
        % nodes{i} = node;
    end

    % Set the leader nodes: mark them as used (squares) and red
    for k = 1:3
        idx = leader_indices(k);
        nodes{idx}.shape = 's';
        nodes{idx}.color = [1 0 0];  % red
    end

    % Connect the 3 leaders in a triangle (complete graph K3)
    for p = 1:3
        for q = p+1:3
            i = leader_indices(p);
            j = leader_indices(q);
            A(i,j) = 1;
            A(j,i) = 1;   % undirected / bidirectional
        end
    end
end
