function val = iePoisson(lambda, nSamp, useSeed)
% Create a matrix of Poisson samples using rate parameters in lambda
%
%   val = iePoisson(lambda,nSamp,useSeed)
%
% The rate parameter can be a scalar, requesting multiple samples, or it
% can be a matrix of rate parameters.
%
% The useSeed flag determines whether or not to return the same value each
% time for a given lambda (0), or to return different values (1).
%
% The algorithm is from Knuth.
% Reference: Knuth routine - found on a web-page reference and also at
%   http://en.wikipedia.org/wiki/Poisson_distribution
%   http://www.columbia.edu/~mh2078/MCS04/MCS_generate_rv.pdf
%
% This script replaces the Matlab poissonrnd function because that function
% is only in the stats toolbox.
%
% The function is used in ISET when we find the pixels with a mean of less
% than 25.  In those cases the normal approximation doesn't work well. In
% that case we over-write the Gaussian shot noise at those locations with
% Poisson random values. We could use this for all of the values if it
% turns out this routine runs fast enough.
%
% Copyright ImagEval, LLC, 2010
%
% 6/3/15  xd  iePoissrnd now uses a randomly generated seed
% 6/4/15  xd  added flag to determine if noise should be frozen
%
% See also:
%    noiseShot

% Examples:
%{
% Examples (see Run Configuration in Debug):
% Matrix form
  nSamp = 128;
  lambda = round(rand(nSamp,nSamp)*10);
  tic, val = iePoisson(lambda); toc
  vcNewGraphWin([],'tall')
  subplot(2,1,1), imagesc(lambda); colormap(gray);colorbar; axis image
  subplot(2,1,2), imagesc(val); colormap(gray); colorbar; axis image

% Multiple samples form
  lambda = 4; nSamp = 1000;
  val = iePoisson(lambda,nSamp);
  vcNewGraphWin; hist(val,50)

%}
%%

if notDefined('lambda'), error('rate parameter lambda required'); end
if notDefined('nSamp'), nSamp = 1; end
if notDefined('useSeed'), useSeed = 1; end

%% Check for stats toolbox and key function.
% This is expected to exist on the user's path.
% Could also run: checkToolbox('Statistics and Machine Learning Toolbox')
try
    if ~useSeed
        % No seed.
        rng('shuffle'); % seeds the random number generator based on the current time.
    end
    
    % Matlab toolbox version is present. Use it.
    if isscalar(lambda)
        % Returns a vector
        val = poissrnd(lambda, [nSamp,1]);
    else
        % Returns a matrix
        val = poissrnd(lambda);
    end
    
catch
    
    % No toolbox.  Sigh.  Check if we have MEX function
    %{
if (exist('iePoissrnd','file')==3)
    if useSeed
        val = iePoissrnd(lambda, nSamp, rand * 12345701);
    else
        val = iePoissrnd(lambda, nSamp);
    end
    if ~useSeed
        p = rng;
        rng(1);
    end
    return;
end
    %}
    
    % Use the local ISET methods
    % Simple implementation, this is slow for large lambda
    % Not recommended.
    
    warning('Using slow poisson random variable generation.  Recommend getting stats toolbox.');
    if isscalar(lambda)
        % Scalar version of the routine
        % Probably we want multiple samples for a single lambda
        val = zeros(1, nSamp);
        for nn = 1 : nSamp
            kk = 0;
            p = 0;
            while p < lambda
                kk = kk + 1;
                p = p - log(rand);
            end
            val(nn) = kk - 1;
        end
        % figure(1); hist(val,50)
    else
        % A matrix or vector of lambdas and we return samples for each
        val = zeros(size(lambda));
        for ii = 1 : numel(lambda)
            kk = 0;
            p = 0;
            while p < lambda(ii)
                kk = kk + 1;
                p = p - log(rand);
            end
            val(ii) = kk - 1;
        end
    end
    
    if ~useSeed
        rng(p);
    end
    
end

end
