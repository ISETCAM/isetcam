function [noisyImage,theNoise] = noiseShot(ISA)
% Add shot noise (Poisson electron noise) into the image data
%
%    [noisyImage,theNoise] = noiseShot(ISA)
%
% The shot noise is Poisson in units of electrons (but not in other units).
% Hence, we transform the (mean) voltage image to electrons, create the
% Poisson noise, and then the signal back to a voltage. The returned
% voltage signal is not Poisson; it has the same SNR (mean/sd) as the
% electron image.
%
% This routine uses the normal approximation to the Poisson when there are
% more than 25 electrons in the pixel.  It uses the Poisson distribution
% when there are fewer than 25 electrons.  The Poisson function we have is
% slow for larger means, so we separate the calculation this way.  If we
% have a fast Poisson generator, we could use it throughout.  Matlab has
% one in the stats toolbox, but we don't want to impose that on others.
%
% See also:  iePoisson
%
% Examples:
%    [noisyImage,theNoise] = noiseShot(vcGetObject('sensor'));
%    imagesc(theNoise); colormap(gray(64))
%
% Copyright ImagEval Consultants, LLC, 2003.

volts          = sensorGet(ISA,'volts');
conversionGain = pixelGet(ISA.pixel,'conversion gain');
electronImage  = volts/conversionGain;

% Use the builtin poissrnd if available, otherwise default to the method
% below.
if exist('poissrnd','builtin')
    noisyImage = poissrnd(electronImage);
    theNoise = noisyImage - electronImage;
else
    % N.B. The noise is Poisson in electron  units. But the distribution in
    % voltage units is NOT Poisson.  The voltage signal, however, does have the
    % same SNR as the electron signal.
    
    % The Poisson variance is equal to the mean. Randn is unit normal (N(0,1)).
    % S*Randn is N(0,S).
    %
    % We multiply each point in the image by the square root of its mean value
    % to create the noise. For most cases this Normal approximation is
    % adequate. But we trap (below) the cases when the value is small and
    % replace it with the Poisson random value.
    theNoise = sqrt(electronImage) .* randn(size(electronImage));
    
    % We add the mean electron and noise electrons together.
    noisyImage = round(electronImage + theNoise);
    
    % Now, we find the small mean values and create a Poisson sample. This is
    % too slow in general because the Poisson algorithm is slow for big
    % numbers.  But it is fast for small numbers. We can't rely on the Stats
    % toolbox being present, so we use this Poisson sampler from Knuth. Create
    % and copy the Poisson samples into the noisyImage
    poissonCriterion = 25;
    [r,c] = find(electronImage < poissonCriterion);
    v = electronImage(electronImage < poissonCriterion);
    if ~isempty(v)
        vn = iePoisson(v);  % Poisson samples
        for ii=1:length(r)
            noisyImage(r(ii),c(ii)) = vn(ii);
            
            % The noise is the Poisson value minus the mean (6/2015, BW)
            theNoise(r(ii),c(ii))   = vn(ii) - v(ii);
        end
    end
    % Convert the noisy electron image back into the voltage signal
    noisyImage = conversionGain*noisyImage;
end

return;
