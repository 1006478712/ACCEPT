function u = bregman_cv_core(f,nx,ny,lambda_reg,breg_it,inner_it,...
                             tol,p,u,u_bar,b,sigma,tau,theta,...
                             init,mu_update,mu0,mu1,useMask,mask)
    
    % dimensions
    dim = ndims(f);
    
    i = 1; j = 1;
    while i <= breg_it % Bregman iteration steps
        stat_u = []; 
        while j <= inner_it && (isempty(stat_u) || ~isempty(stat_u) && stat_u(end) >= tol) % inner TV iteration steps
            %%% step 1 : update p according to 
            %%% p_(n+1) = (I+delta F*)^(-1)(p_n + sigma K u_bar_n)
            % update dual p
            arg1 = p + sigma * grad(u_bar,'shift');
            p = arg1 ./ max(1,repmat(sqrt(sum(arg1.^2,3)),[1 1 dim])); %different for aniso TV

            %%% step 2: update u according to
            %%% u_(n+1) = (I+tau G)^(-1)(u_n - tau K* p_(n+1))
            u_old = u;
            arg2 =  (u + tau * div(p,'shift')) - tau/lambda_reg * ((f - mu1).^2 - (f - mu0).^2 - lambda_reg * b);
            u = max(0, min(1,arg2));
            stat_u(j) = (nx*ny)^(-1) * (sum((u(:) - u_old(:)).^2)/sum(u_old(:).^2));         

            %%% step 3: update u_bar according to
            %%% u_bar_(n+1) = u_(n+1)+ theta * (u_(n+1) - u_n)
            u_bar = u + theta * (u - u_old);

            % update mean values (mu0 and mu1)
            if (mod(j,mu_update) == 0) % && sum(sum((u>=0.5)))>0 && sum(sum((u<0.5)))>0
                if max(max((init<0.5))) == 1 && max(max((init>=0.5))) == 1
                    mu0 = max(mean(mean(f(init<0.5))),0); % mean value outside object
                    mu1 = max(mean(mean(f(init>=0.5))),0); % mean value inside object
                elseif max(max((init<0.5))) == 0
                    mu0 = min(f(:));
                    mu1 = mean(mean(f(init>=0.5)));
                elseif max(max((init>=0.5))) == 0
                    mu0 = mean(mean(f(init<0.5)));
                    mu1 = max(f(:));
                end
                if useMask
                    f(mask) = mu0;
                end
            end

            % update inner index
            j = j + 1;

        end

        % update b (outer bregman update)
        b = b + 1/lambda_reg * ((f - mu0).^2 - (f - mu1).^2);

        % update outer index
        i = i + 1; j = 1;
    end
    
    %----------
    
    % divergence function used within the matlab version of bregman_cv
    function div_v = div(v,method)
        persistent Dx_div Dy_div

        N = size(v,2);
        M = size(v,1);

        if size(Dx_div,1) ~= N || size(Dy_div,1) ~= M
            Dx_div = [];
            Dy_div = [];
        end

        if isempty(Dx_div) && strcmp(method,'lr')
            Dx_div = spdiags([-ones(N,1) ones(N,1)],[0 1],N,N); Dx_div(N,:) = 0;
            Dy_div = spdiags([-ones(M,1) ones(M,1)],[0 1],M,M); Dy_div(M,:) = 0;
        end

        if strcmp(method,'shift')
            v = single(v);
            % forward euler discretization with zero gradient boundary
            % -> cf. [Chambolle - an algorithm for total variation minimization and
            %    applications (2004)]
            % -> !!! in 1D v should be a column vector !!!
            % -> Assumption: \Omega = [0,1] x [0,1] x [0,1], i.e. spatial step sizes
            %    are hx = 1 / nx, hy = 1 / ny and hz = 1 / nz
            % v = input matrix (muplitple layers in 4th dimension, i.e. if v = grad_u with u 2D
            % then v(:,:,:1) = grad_x_u and v(:,:,:2) = grad_y_u.)

            [nx, ny, ~] = size(v);
            % hx = 1/nx; hy = 1/ny; hz = 1/nz;
            hx = 1; hy = 1;

            div_v = hx^(-1) * cat(1, v(1,:,1), v(2:nx-1,:,1) - v(1:nx-2,:,1), -v(nx-1,:,1));
            div_v = div_v + hy^(-1) * cat(2, v(:,1,2), v(:,2:ny-1,2) - v(:,1:ny-2,2), -v(:,ny-1,2));
        elseif strcmp(method,'lr')
            %% GRAD DIV, left-right definition
            % (FASTEST, but only works for double images, since no sparse single arrays available)
            div_v = v(:,:,1)*Dx_div + Dy_div'*v(:,:,2);
        end
    end

    % gradient function used within the matlab version of bregman_cv
    function grad_u = grad(u,method)
        persistent Dx_grad Dy_grad

        N = size(u,2);
        M = size(u,1);
        if size(Dx_grad,1) ~= N || size(Dy_grad,1) ~= M
            Dx_grad = [];
            Dy_grad = [];
        end

        if isempty(Dx_grad) && strcmp(method,'lr')
            Dx_grad = spdiags([-ones(N,1) ones(N,1)],[0 1],N,N); Dx_grad(N,:) = 0;
            Dy_grad = spdiags([-ones(M,1) ones(M,1)],[0 1],M,M); Dy_grad(M,:) = 0;
        end

        if strcmp(method,'shift')
            u = single(u);
            % forward euler discretization with zero gradient boundary
            % -> cf. [Chambolle - an algorithm for total variation minimization and
            %    applications (2004)]
            % -> !!! in 1D u should be a column vector !!!
            % -> Assumption: \Omega = [0,1] x [0,1] x [0,1], i.e. spatial step sizes
            %    are hx = 1 / nx, hy = 1 / ny and hz = 1 / nz
            [nx, ny] = size(u);
            % hx = 1/nx; hy = 1/ny; hz = 1/nz;
            hx = 1; hy = 1;

            grad_u(:,:,1) = hx^(-1) * cat(1, u(2:nx,:) - u(1:nx-1,:), zeros(1,ny));
            grad_u(:,:,2) = hy^(-1) * cat(2, u(:,2:ny) - u(:,1:ny-1), zeros(nx,1));
        elseif strcmp(method,'lr')
            %% GRAD DIV, left-right definition
            % (FASTEST, but only works for double images, since no sparse single arrays available) 
            if issparse(u*Dx_grad') || issparse(Dy_grad*u)
                grad_u = cat(3,full(u*Dx_grad'),full(Dy_grad*u));
            else 
                grad_u = cat(3,u*Dx_grad',Dy_grad*u);
            end
        end
    end
    
end