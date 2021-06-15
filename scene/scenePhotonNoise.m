function [noisyPhotons,theNoise] = scenePhotonNoise(scene,rectOrLocs)
% Add Poisson photon noise to the scene radiance data
%
%  [noisyPhotons,theNoise] = scenePhotonNoisePhotonNoise(scene,rectOrLocs)
%
% This routine uses the normal approximation to the Poisson when there are
% more than 15 photons.  It uses the true Poisson distribution when there
% are fewer than 15 photons.
%
% The Poisson function we have is slow for larger means, so we separate the
% calculation this way.  If we have a fast Poisson generator, we could use
% it throughout.  Matlab has one in the stats toolbox, but we don't want to
% impose the stats toolbox requirement on others.
%
% See also:  oiPhotonNoise, noiseShot, iePoisson, v_photonNoise
%
% Examples:
%    scene = sceneCreate('uniform');
%    [noisyPhotons,theNoise] = scenePhotonNoise(oi);
%    vcNewGraphWin; tmp = noisyPhotons(:,:,10); tmp = tmp(tmp > 2*10^13); histogram(tmp(:))
%    imagesc(noisyPhotons(:,:,10)); colormap(gray(64))
%
% Copyright ImagEval Consultants, LLC, 2013.

if ieNotDefined('roiLocs')
    photons = sceneGet(scene,'photons');
else
    photons = sceneGet(scene,'photons',rectOrLocs);
end

% The Poisson variance is equal to the mean. Randn is unit normal (N(0,1)).
% S*Randn is N(0,S).
%
% We multiply each point in the image by the square root of its mean value
% to create the noise. For most cases this Normal approximation is
% adequate. But we trap (below) the cases when the value is small and
% replace it with the Poisson random value.
theNoise = sqrt(photons) .* randn(size(photons));

% We add the mean electron and noise electrons together.
noisyPhotons = round(photons + theNoise);
% When the signal is very large, say 10^14, the noise is only 10^7.  This
% is very small and you see basically nothing. But if the signal is small, you have a chance of seeing something in
% these plots.

% Now, we find the small mean values and create a Poisson sample. This is
% too slow in general because the Poisson algorithm is slow for big
% numbers.  But it is fast for small numbers. We can't rely on the Stats
% toolbox being present, so we use this Poisson sampler from Knuth. Create
% and copy the Poisson samples into the noisyImage
poissonCriterion = 15;
[r,c] = find(photons < poissonCriterion);
v = photons(photons < poissonCriterion);
if ~isempty(v)
    vn = iePoisson(v);  % Poisson samples
    for ii=1:length(r)
        theNoise(r(ii),c(ii))   = vn(ii);
        % For low mean values, we *replace* the mean value with the Poisson
        % noise; we do not *add* the Poisson noise to the mean. Hence the
        % following line is incorrected and was replaced with the
        % subsequent line:
        % noisyImage(r(ii),c(ii)) = electronImage(r(ii),c(ii)) + vn(ii);
        noisyPhotons(r(ii),c(ii)) = vn(ii);
    end
end

end

