function q_norm = normalizeQuaternion(q)
    mag = sqrt(sum(q.^2));
    if mag < 1e-10
        q_norm = [1; 0; 0; 0]; % Default identity quaternion
    else
        q_norm = q/mag;
    end
end
