% v_sensorPoisson
%
% Check the Poisson returns when noiseFlag = -2
%
%

%%
ieInit;

%% Make a uniform scene, pretty big
scene = sceneCreate('uniform');  % Mean luminance is 100 cd/m2
scene = sceneSet(scene,'fov',10);

% Create the optical image
oi = oiCreate; oi = oiCompute(oi,scene);

%% For a monochrome sensor, look at the center of the uniform image
sensor = sensorCreate('monochrome');
fov = 8;
sensor = sensorSetSizeToFOV(sensor,fov,oi);

% Set the noise flag to Poisson noise only
sensor = sensorSet(sensor,'noise flag',-2);

sensor = sensorSet(sensor,'exp time',0.025*(3*1e-4));  % Very short exposure
sensor = sensorCompute(sensor,oi);
% sensorWindow(sensor,'scale',true);

%% Plot histogram and the Poisson histogram together

e = sensorGet(sensor,'electrons');
lambda = mean(e(:));

%%
vcNewGraphWin;
nSamps = length(e(:));
eHist = histogram(e(:),'Normalization','probability');
hold on
val = iePoisson(lambda,nSamps);
pHist = histogram(val(:),'Normalization','probability');
pHist.NumBins = eHist.NumBins*2;
hold off
xlabel('Electrons'); ylabel('Count')

%% Poisson formula for lambda
samples  = 0:round(5*lambda);
nSamples = length(samples);
p = zeros(nSamples,1);
for ii=0:(nSamples-1)
    p(ii+1) = exp(-lambda)*((lambda^ii)/factorial(ii));
end
hold on
plot(samples,p,'ro--');


%% Now for a longer exposure
sensor = sensorSet(sensor,'exp time',0.025*(3*1e-4)*100);  % Long exposure
sensor = sensorCompute(sensor,oi);
% sensorWindow(sensor,'scale',true);

%% Plot histogram and the Poisson histogram together

e = sensorGet(sensor,'electrons');
lambda = mean(e(:));

%%
ieNewGraphWin;
nSamps = length(e(:));
eHist = histogram(e(:),'Normalization','probability');
xlabel('Electrons'); ylabel('Count')


%% Poisson formula means it should be fit by a Gaussian and
% the std dev should be sqrt(mean)
%
sd = sqrt(lambda);
[mn,sigma] = normfit(e(:));
fprintf('\n-----\n');
fprintf('Nominal: std dev %.2f\n',sd);
fprintf('Data:    std dev %.2f\n',sigma);
fprintf('-----\n');

%% END