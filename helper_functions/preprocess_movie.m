function [M, config] = preprocess_movie(M, config)
% Wrapper for collection of preprocessing routines

    % Below are standard preprocessing steps, performed unless skipped by
    % user
    if config.preprocess

        % Find and fix spatial slices that are occasionally zero due to
        % frame registration (e.g. turboreg)
        if config.fix_zero_FOV_strips
            M = remove_zero_edge_pixels(M);
        end

        % Median filtering for hot or dead pixels
        if isfield(config, 'medfilt_outlier_pixels') && config.medfilt_outlier_pixels
            M = medfilt_outliers(M);
        end
    
    
        % delta F/F
        [M, m] = compute_dfof(M, config.skip_dff);
        config.F_per_pixel = m;
        
        % Mild highpass filtering for reducing regional fluctuations
        if ~isinf(config.spatial_highpass_cutoff)
            M = spatial_bandpass(M, config.avg_cell_radius, ...
                config.spatial_highpass_cutoff, inf, config.use_gpu);
        end

        % Apply temporal denoising (slow)
        if config.temporal_denoising
            M = temporal_denoising(M);
        end
        
    
        % Mask movie with user provided and/or circular mask
        if ~isempty(config.movie_mask)
            M = bsxfun(@times, M, config.movie_mask);
        end

        % Remove wandering signal baseline
        if isfield(config, 'avg_event_tau')
            M = correct_baseline(M, config.avg_event_tau, ...
                config.remove_background, config.use_gpu);
        end
    
    else
        % Set mean fluorescence per pixel to all ones
        [h, w, ~] = size(M);
        config.F_per_pixel = ones(h, w);
    end
    
    
end
