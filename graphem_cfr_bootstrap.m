% N = number of samples (use e.g. N = 50 samples)
% We assume time decreases with the rows of "field" and "proxy".
% Note: time is assumed to go forward (i.e., field(1,:) is the oldest time).
%       calib can either be a list of indices or a logical vector. In order for 
%       the block bootstrap to work properly, 'calib' has to be an interval of time.

function [field_r_all, boot_indices] = graphem_cfr_bootstrap(field,proxy,calib,opt,N)

	opt.bootstrap = 1;
	[n,pp] = size(proxy);
	
	blocksize_calib = 2;
	blocksize_verif = 2;
	blocksize = 2;  % For uniform sampling
	
	uniform = 0;   % Sample the calibration and verification periods separately
	
	[nt,pt] = size(field);
	p = pt + pp;
	
	% Construct bootstrap indices
	boot_indices = zeros(N,n);
        if islogical(calib)
            calib = find(calib);
        end
        
        calib_e = length(calib);
        verif = setdiff(1:n, calib);
        verif_e = n-calib_e;
	
	if uniform
        nb_blocks = ceil(n/blocksize);
        for i=1:N
            blocks = unidrnd(n-blocksize+1,nb_blocks,1);
            for j=1:nb_blocks-1
                boot_indices(i,((j-1)*blocksize+1):j*blocksize) = blocks(j):(blocks(j)+blocksize-1);
            end
            boot_indices(i,((nb_blocks-1)*blocksize+1):n) = blocks(nb_blocks):(blocks(nb_blocks)+n-(nb_blocks-1)*blocksize-1);
        end
    else
        % Verification period
        nb_blocks = ceil(length(verif)/blocksize_verif);
        for i=1:N
            blocks = unidrnd(verif_e-blocksize_verif+1,nb_blocks,1);
            for j=1:nb_blocks-1
                boot_indices(i,calib_e+((j-1)*blocksize_verif+1):calib_e+j*blocksize_verif) = verif(blocks(j):(blocks(j)+blocksize_verif-1));
            end
            boot_indices(i,calib_e+((nb_blocks-1)*blocksize_verif+1):n) = verif(blocks(nb_blocks):(blocks(nb_blocks)+verif_e-(nb_blocks-1)*blocksize_verif-1));
        end
        
        % Calibration period
        nb_blocks = ceil(length(calib)/blocksize_calib);
        for i=1:N
            blocks = unidrnd(calib_e-blocksize_calib+1, nb_blocks,1);
            for j=1:nb_blocks-1
                boot_indices(i,((j-1)*blocksize_calib+1):j*blocksize_calib) = calib(blocks(j):(blocks(j)+blocksize_calib-1));
            end
            boot_indices(i,((nb_blocks-1)*blocksize_calib+1):calib_e) = calib(blocks(nb_blocks):(blocks(nb_blocks)+calib_e-(nb_blocks-1)*blocksize_calib-1));
        end

    end
    
    % Start bootstrap
    field_r_all = zeros(N, nt, pt);
    
    for i=1:N
		% Construct current bootstrap sample
		field_i = field(boot_indices(i,:),:);
		proxy_i = proxy(boot_indices(i,:),:);
		
		[~, diagn_i] = graphem_cfr(field_i,proxy_i,1:calib_e,opt);
		Mi = diagn_i.M;   % Estimated mean for i-th bootstrap sample
		Ci = diagn_i.C;   % Estimated covariance for i-th bootstrap sample
		
		% Reconstruct original field using estimated parameters
		opt2 = opt;
		opt2.useggm = 0;
		opt2.maxit = 1;
		% Set model parameters
		opt2.M0 = Mi;
		opt2.C0 = Ci;
		% Perform reconstruction
		[field_r_all(i,:,:), ~] = graphem_cfr(field,proxy,calib,opt2);
		
    end 

end
