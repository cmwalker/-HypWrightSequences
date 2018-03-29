function [ pulseParams ] = DesignSpectralSpatial( mets,varargin )
%DESIGNSPECTRALSPATIAL Designs a spectral spatial pulse using UCSF code
%   Detailed explanation goes here
import HypWrightSequences.*
%% Parse Inputs
p = inputParser;
addParameter(p,'ss_type','EP Whole'); % Excitation Type
addParameter(p,'ptype','ex'); % Pulse Type
addParameter(p,'Nucleus','Carbon'); % Nuclei
addParameter(p,'MaxDuration',25e-3); % Maximum durration
addParameter(p,'SpectCorrect',1); % No Idea
addParameter(p,'fctr',0);% force pulse design to optimize for center of frequency specification
addParameter(p,'s_ftype','min');% type of spectral filter
addParameter(p,'sliceThickness',1);% slice tickness (m)
addParameter(p,'timeBWProdut',4);% Time bandwidth product
addParameter(p,'z_ftype','ls');% Slice filter design
addParameter(p,'d1',0.01);% Pass band ripple
addParameter(p,'d2',0.01);% Stop band ripple
addParameter(p,'opts',[]) % Design options
addParameter(p,'verbose',false);% verbose


parse(p,varargin{:});
%% Fill Values
ss_type = p.Results.ss_type;
ptype = p.Results.ptype;
Nucleus = p.Results.Nucleus;
MaxDuration = p.Results.MaxDuration;
SpectCorrect = p.Results.SpectCorrect;
fctr = p.Results.fctr;
s_ftype = p.Results.s_ftype;
z_thk = p.Results.sliceThickness*100; %put slice thickness in cm as required for UCSF code
z_tb = p.Results.timeBWProdut;
z_ftype = p.Results.z_ftype;
z_d1 = p.Results.d1;
z_d2 = p.Results.d2;
opts = p.Results.opts;
verbose = p.Results.verbose;

% Design Spectral Spatial Pulse - Uses teh UCSF pulse dsign
% GENERAL PULSE PARAMETERS
if isempty(opts)
    opt = ss_opt({'Nucleus', Nucleus,'Max Duration', MaxDuration,...
        'Spect Correct', SpectCorrect});
end
% create vectors of angles, ripples, and band edges for input to pulse design
[fspec, a_angs, d] = create_freq_specs(mets);

% DESIGN THE PULSE!
[g,rf,fs,tAxis] = ...
    ss_design_quick(z_thk, z_tb, [z_d1 z_d2], fspec, a_angs, d, ptype, ...
    z_ftype, s_ftype, ss_type, fctr,0,~verbose);
tmpFreq = cell2mat({mets.f});
pulseCenter = (max(tmpFreq)-min(tmpFreq))/2; % Center frequency of the output spectral spatial pulse
pulseOffset = (-max(tmpFreq))+pulseCenter; %Shift pulse to match up with the ppms of the phantom
rf = rf.*exp(1i*2*pi*pulseOffset*tAxis); %Mix up the RF pulse to the carrier frequency
pulsetime = tAxis(floor(length(tAxis)/2)); % center of the RF pulse (sec)
bShape = [zeros(1,numel(g));zeros(1,numel(g));g]*1e-2; % Guild slice select gradient

% Pack the pulse into a struct
pulseParams = struct('rfPulseShape',rf*1e-4,'bShape',bShape,'tAxis',tAxis,...
    'pulseTime',pulsetime);
end

