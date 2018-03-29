function [returnPulse, gradPulse] = RFPulseSelector(t,gamma,B0,pulseType,pulseParams,varargin)
%RFPULSESELECTOR Helper function for selecting a RF-Pulse
% Slects the RF-pulse to use and builds it with given inputs
% Inputs:
% t - The Center Time of the pulse (sec)
% gamma - the gyromagnetic ration of the nuclei to be excited (rad/sec/T)
% pulseType - String to determin the pulse
% pulseParams - the parameters for the pulse
% Outputs:
% returnPulse - the RF RF-pulse to be used in simulation
gradPulse = [];
import HypWright.*
p = inputParser;
addParameter(p,'name','noName'); % Optional Name for the pulse
parse(p,varargin{:});
pulseName = p.Results.name;
switch lower(pulseType)
    case 'bsinc' % Creates a blackman filtered sinc pulse
        %% Parse Pulse Parameters
        defaults = struct('excitationBW',5000,'flipAngle',20,...
            'nLobes',5,'offset',0);
        pulseParams = FillDefaults(pulseParams,defaults);
        excitationBW = pulseParams.excitationBW; % Excitatin bandwith for the pulse (Hz)
        flipAngle = pulseParams.flipAngle; % Flip angle for the pulse (degrees)
        nLobes = pulseParams.nLobes; % number of lobes in the sinc pulse
        offset = pulseParams.offset; % frequence offset for the puse (Hz)
        %% Creat Pulse
        returnPulse = SincPulse(t,excitationBW,deg2rad(flipAngle)/gamma,...
            gamma*B0+(offset*2*pi),'lobes',nLobes,'name',pulseName);
    case 'slr' % Creates a SLR Pulse using the rf-Desing Tools
        %% Parse Pulse Parameters
        defaults = struct('excitationBW',5000,'flipAngle',20,'durration',1e-3,...
            'nPoints',512,'offset',0,'ftype','ls','ptype','st',...
            'd1',0.01,'d2',0.01,'pclsfrac',1.5);
        pulseParams = FillDefaults(pulseParams,defaults);
        excitationBW = pulseParams.excitationBW; % Excitatin bandwith for the pulse (Hz)
        flipAngle = pulseParams.flipAngle; % Flip angle for the pulse (degrees)
        durration = pulseParams.durration; % Pulse durration
        nPoints = pulseParams.nPoints; % number of lobes in the sinc pulse
        offset = pulseParams.offset; % frequence offset for the puse (Hz)
        %ptype - pulse type.  Options are:
        % st  - small tip angle(default)
        % ex  - pi/2 excitation pulse
        % se  - pi spin-echo pulse
        % sat - pi/2 saturation pulse
        % inv - inversion pulse
        ptype = pulseParams.ptype;
        %ftype - filter design method.  Options are:
        % ms  - Hamming windowed sinc (an msinc)
        % pm  - Parks-McClellan equal ripple
        % ls  - Least Squares           (default)
        % min - Minimum phase (factored pm)
        % max - Maximum phase (reversed min)
        ftype = pulseParams.ftype;
        d1 = pulseParams.d1;%d1 - Passband ripple (default = 0.01)
        d2 = pulseParams.d2;%d2 - Stopband ripple (default = 0.01)
        pclsfrac = pulseParams.pclsfrac;%pclsfrac - pcls tolerance (default = 1.5)
        %% Creat Pulse
        returnPulse = SLRPulse(nPoints,excitationBW,deg2rad(flipAngle)/gamma,t,...
            durration,gamma*B0+(offset*2*pi),pulseName,...
            'ftype',ftype,'ptype',ptype,'d1',d1,'d2',d2,'pclsfrac',pclsfrac);
    case 'bruker' % Uses the Bruker RF-Pulse Waveforms
        %% Parse Pulse Parameters
        defaults = struct('excitationBW',5000,'flipAngle',20,...
            'type','sinc','offset',0);
        pulseParams = FillDefaults(pulseParams,defaults);
        excitationBW = pulseParams.excitationBW; % Excitatin bandwith for the pulse (Hz)
        flipAngle = pulseParams.flipAngle; % Flip angle for the pulse (degrees)
        type = pulseParams.type; % Type of pulse shape
        offset = pulseParams.offset; % frequence offset for the puse (Hz)
        %% Creat Pulse
        returnPulse = BrukerPulse(t,'sinc',excitationBW,...
            deg2rad(flipAngle)/gamma,gamma*B0+(offset*2*pi),pulseName);
    case 'abstract' % Generates a pulse with an abstract RF and gradient waveform
        rfPulseShape = pulseParams.rfPulseShape;
        bShape = pulseParams.bShape;
        tAxis = pulseParams.tAxis;
        %% Creat Pulse
        returnPulse = AbstractRFPulse(t,gamma*B0,rfPulseShape,...
            tAxis-tAxis(floor(length(tAxis)/2)),[pulseName,'-RF']);
        if ~isempty(pulseParams.bShape)
            gradPulse = AbstractGradientPulse(t,bShape,tAxis,[pulseName,'-Grad']);
        else
            gradPulse = [];
        end
    otherwise % Error for non recognized pulse types
        error('Pulse type not recognized. Pulse:%s',pulseType)
end
end

