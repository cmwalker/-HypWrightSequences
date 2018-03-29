function [ PS,ADC ] = PulseAcquireSliceSelectiveSequence(varargin)
%PULSEACQUIRESliceSelective Generates a Pulse Acquire Sequence for the HypWight
%Simulation Platform
%   Builds a Basic Puse Acquire Sequence
% Inputs:
% nPoints -Number of readout points per TR [512]
% nTRs -  Number of TRs [60]
% TR -  Number of TRs [2]
% startTime - Start of the first puse (sec) [0]
% sampleBW - Read out Bandwidth (Hz) [5000]
% centerFreq - Central readout frequency (Hz)
% gamma - Gyromagnetic ratio (rads/sec/T) [67.262e6 (Carbon)]
% B0 - The main static magnetic field (T) [3]
% pulseType - The type of RF-Pulse [Blackman Sinc]
% pulseParams - The Pulse Parameters (depends on the pulse type)
% sliceTickness - The Slice Thickness (m)
% Outputs:
% PS - The Pusle Sequence to be used in the simulation
% ADC - The readout times

import HypWright.*
%% Parse Inputs
p = inputParser;
addParameter(p,'nPoints',512); % Number of readout points per TR
addParameter(p,'nTRs',60); % Number of TRs
addParameter(p,'TR',2); % Repetition time (sec)
addParameter(p,'startTime',0); % Start of the first puse (sec)
addParameter(p,'sampleBW',5000); % Read out Bandwidth (Hz)
addParameter(p,'pulseType','bSinc'); % The type of RF-Pulse
addParameter(p,'pulseParams',[]); % The Pulse Parameters
addParameter(p,'sliceThickness',1); % Slice Thickness (m)
addParameter(p,'rewindTime',1e-9); % SliceSlect Rewind Time (sec)
addParameter(p,'gamma',67.262e6); % Gyromagnetic ratio (rads/sec/T)
addParameter(p,'B0',3); % The main static magnetic field (T)
%% Might want to have an echo Time insread of a rewind time.
parse(p,varargin{:});
%% Fill Values
nPoints = p.Results.nPoints;
nTRs = p.Results.nTRs;
TR = p.Results.TR;
startTime = p.Results.startTime;
gamma = p.Results.gamma;
B0 = p.Results.B0;
sampleBW = p.Results.sampleBW;
pulseType = p.Results.pulseType;
pulseParams = p.Results.pulseParams;
sliceThickness = p.Results.sliceThickness;
rewindTime = p.Results.rewindTime;



%% Build The Sequence
ADC = zeros(nTRs,nPoints);
PS = PulseSequence;
for i = 1:nTRs
    [S, G] = RFPulseSelector(TR*(i-1)+startTime,gamma,B0,pulseType,pulseParams,...
        'name',sprintf('Excitation%d',i));
    PS.addPulse(S)
    if isempty(G)
        %% Calculate sequence dependent varaibles
        excitationBW = pulseParams.excitationBW;
        sliceZ = 2*pi*excitationBW/(sliceThickness*gamma);
        sliceGrad = LinearGradientPulse(S.center,S.durration,...
            [0,0,sliceZ],sprintf('ReadGrad%d',i));
        PS.addPulse(sliceGrad)
        SliceReWind = sliceZ/2*(S.durration/rewindTime);
        reWindGrad = LinearGradientPulse(S.endTime+rewindTime/2,rewindTime,...
            [0,0,-SliceReWind],sprintf('RewindGrad%d',i));
        PS.addPulse(reWindGrad)
        ADC(i,:) = reWindGrad.endTime+((1:nPoints)-1).*1/sampleBW;
    else
        sliceGrad = G;
        PS.addPulse(sliceGrad)
        ADC(i,:) = sliceGrad.endTime+((1:nPoints)-1).*1/sampleBW;
    end
end
end
