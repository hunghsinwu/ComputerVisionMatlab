%% Color Modeling System Initialization
% Initialize the wavelength data
i_nm_min = 380;
i_nm_max = 730;
i_nm_int = 10;
o_nm_min = 380;
o_nm_max = 730;
o_nm_int = 10;

% Read in the ink primaries
fname_inkdc = '../DataMeasure/PrinterInformation/CMYKRGBLinearDC.txt';
fname_inkspec = '../DataMeasure/PrinterInformation/CMYKRGBLinearRef.txt';
[ink_dc, ink_spec] = ...
    data_parser.read_inkjet_ink_primaries( ...
    fname_inkdc, fname_inkspec,...
    i_nm_min, i_nm_int, i_nm_max,...
    o_nm_min, o_nm_int, o_nm_max);

% Read in the Neugebauer Primaries
fname_dc = '../DataMeasure/PrinterInformation/CMYKRGBCellularDC.txt';
fname_spec = '../DataMeasure/PrinterInformation/CMYKRGBCellularRef.txt';

[neugebauer_dc, neugebauer_ref] = ...
    data_parser.read_inkjet_neugebauer_primaries( ...
    fname_dc, fname_spec,...
    i_nm_min, i_nm_int, i_nm_max,...
    o_nm_min, o_nm_int, o_nm_max );

fname_cellular_dc = '../DataMeasure/PrinterInformation/CMYKRGBCellularDC.txt';
fname_cellular_spec = '../DataMeasure/PrinterInformation/CMYKRGBCellularRef.txt';
[cellular_dc, cellular_ref] = ...
    data_parser.read_inkjet_cellular( ...
    fname_cellular_dc, fname_cellular_spec,...
    i_nm_min, i_nm_int, i_nm_max,...
    o_nm_min, o_nm_int, o_nm_max );

% Read in the paper reflectance
[paper_spec] = data_parser.read_inkjet_paper( ...
    fname_dc, fname_spec, ...
    i_nm_min, i_nm_int, i_nm_max,...
    o_nm_min, o_nm_int, o_nm_max );

inkjet = color_model.Minkjet('HPZ3100');

inkjet.init_parameters( 11, ... % Power factor of Nelson 
    0, 100, ...                % The min, max DC values for Neugbauer prim
    0, 50, 100,...              % The min, mid, max DC values for Cellular prim
    o_nm_min, o_nm_int, o_nm_max );

inkjet.init_paper( paper_spec );

inkjet.init_ink_prim( ink_dc, ink_spec, 256 );

inkjet.init_area2dc_table( );

inkjet.init_neugebauer_prim( neugebauer_dc, neugebauer_ref);

inkjet.init_cellular_prim( cellular_dc, cellular_ref );

inkjet.init_cellular_area2areac_table( );

wp = inkjet.get_d65wp();

cie = color_tool.cie_struct( o_nm_min:o_nm_int:o_nm_max);

%% Load skin reflectance 
identfication_faces = dlmread('../DataMeasure/SkinMeasurement/Identification_HumanFace.txt');
idx_faces = identfication_faces( find( identfication_faces(:,2) == 1 ), 1);
idx_faces = idx_faces + 1;
load('../DataMeasure/SkinMeasurement/faceRef.mat');
read_in_skin_ref = faceRef(:, idx_faces)';

skin_ref = color_tool.ref2ref( ...
    read_in_skin_ref, ...
    400, 2, 700, o_nm_min, o_nm_int, o_nm_max );

%% PART I: Predict how's the forward model
% fname_forward_test_dc = '.\DataCalibration\CMYKRGB02575DC.txt';
% fname_forward_test_spec = '.\DataCalibration\CMYKRGB02575Ref.txt';
fname_forward_test_cellular_dc = './RESULTS/20090611_Cellular/HHPrinterDC4_Cellular.txt';
test_forward_cellular_dc = dlmread(fname_forward_test_cellular_dc);
test_forward_cellular_dc = test_forward_cellular_dc(:,1:end);
forward_cellular_pred_ref = inkjet.dc2spectrum_cellular( test_forward_cellular_dc );
[forward_cellular_prim_rms, forward_cellular_prim_dE] = ...
    color_tool.ref_summary( ...
        skin_ref, 'Printed & Measured',...
        forward_cellular_pred_ref, 'Forward Cellular Predicted',...
        cie.cmf2deg, cie.cmf2deg,...
        cie.illD65, cie.illD65,...
        color_tool.ref2xyz(paper_spec, cie.cmf2deg, cie.illD65) );

fname_forward_test_neug_dc = './RESULTS/20090611_Cellular/HHPrinterDC4_Neug.txt';
test_forward_neug_dc = dlmread(fname_forward_test_neug_dc);
test_forward_neug_dc = test_forward_neug_dc(:,1:end);
forward_neugbauer_pred_ref = inkjet.dc2spectrum( test_forward_neug_dc );
[forward_neug_prim_rms, forward_neug_prim_dE] = ...
    color_tool.ref_summary( ...
        skin_ref, 'Printed & Measured',...
        forward_neugbauer_pred_ref, 'Forward Neugbauer Predicted',...
        cie.cmf2deg, cie.cmf2deg,...
        cie.illD65, cie.illD65,...
        color_tool.ref2xyz(paper_spec, cie.cmf2deg, cie.illD65) );

fname_forward_cell_printer_spec = './RESULTS/20090611_Cellular/HHPrinterDC4_CellularReadings.txt';
forward_cell_printer_forward_ref = dlmread(fname_forward_cell_printer_spec);
forward_cell_printer_forward_ref = color_tool.ref2ref( ...
        forward_cell_printer_forward_ref(:,1:end), ...
        i_nm_min, i_nm_int, i_nm_max, ...
        o_nm_min, o_nm_int, o_nm_max );
[forward_skin_cellular_prim_rms, forward_skin_cellular_prim_dE] = ...
    color_tool.ref_summary( ...
        skin_ref, 'Skin Real',...
        forward_cell_printer_forward_ref, 'Forward Cellular Printer',...
        cie.cmf2deg, cie.cmf2deg,...
        cie.illD65, cie.illD65,...
        color_tool.ref2xyz(paper_spec, cie.cmf2deg, cie.illD65) );

fname_forward_neug_printer_spec = './RESULTS/20090611_Cellular/HHPrinterDC4_NeugReadings.txt';
forward_neug_printer_forward_ref = dlmread(fname_forward_neug_printer_spec);
forward_neug_printer_forward_ref = color_tool.ref2ref( ...
        forward_neug_printer_forward_ref(:,1:end), ...
        i_nm_min, i_nm_int, i_nm_max, ...
        o_nm_min, o_nm_int, o_nm_max );
[forward_skin_neug_prim_rms, forward_skin_neug_prim_dE] = ...
    color_tool.ref_summary( ...
        skin_ref, 'Skin Real',...
        forward_neug_printer_forward_ref, 'Forward Neugbauer PrinterPredicted',...
        cie.cmf2deg, cie.cmf2deg,...
        cie.illD65, cie.illD65,...
        color_tool.ref2xyz(paper_spec, cie.cmf2deg, cie.illD65) );

worst_idx = find( forward_cellular_prim_dE == max(forward_cellular_prim_dE) );
fprintf( '\n The worst dE happens in: %dth patch\n', worst_idx );
%% Analyze
for idx=1:size(skin_ref,1)
    h = figure(),
    plot(skin_ref(idx,:), 'Color', [0 0 0], 'LineWidth', 2)
    hold on
    plot( forward_cellular_pred_ref(idx, :), 'Color', [0 0 1] );
    plot( forward_neugbauer_pred_ref(idx, :), 'Color', [1 0 0] );
    axis([0 36 0 1]);
    legend('Measured', 'Cellular', 'Neug')
    fname_write = sprintf('Index - %d', idx);
    title(fname_write);
    drawnow;
    saveas(h, strcat('./RESULTS/20090615_Comparison/',fname_write),'png' );
    close;
end
%% PART II: Predict how's the forward + inverse model works on the Neugbaure Celluar patches
pred_neugebauer_dcs = inkjet.spectrum2dc( neugebauer_ref );
pred_neugebauer_ref = inkjet.dc2spectrum( pred_neugebauer_dcs );
[neug_rms, neug_dE] = ...
    color_tool.ref_summary( ...
        neugebauer_ref, 'Neug Measured', ...
        pred_neugebauer_ref, 'Neug Predicted',...
        cie.cmf2deg, cie.cmf2deg,...
        cie.illD65, cie.illD65,...
        color_tool.ref2xyz(paper_spec, cie.cmf2deg, cie.illD65) );

%% PART III: Predict the Color Checker
cc_ref_src = color_tool.macbeth_cc( inkjet.get_lambdas );

%cc_ref_src = cc_ref_src(:,:);
    
guess_cc_area = inkjet.spectrum2area_guess( cc_ref_src );

cc_cellular_pred_dcs = inkjet.spectrum2dc_cellular( cc_ref_src, guess_cc_area );
cc_cellular_pred_ref = inkjet.dc2spectrum_cellular( cc_cellular_pred_dcs );
[cc_pred_cellular_rms, cc_pred_cellular_dE] = ...
    color_tool.ref_summary( ...
        cc_ref_src, 'Color Checker Measured', ...
        cc_cellular_pred_ref, 'Color Checker Cellular Predicted',...
        cie.cmf2deg, cie.cmf2deg,...
        cie.illD65, cie.illD65,...
        wp );

cc_neug_pred_dcs = inkjet.spectrum2dc( cc_ref_src, guess_cc_area );
cc_neug_pred_ref = inkjet.dc2spectrum( cc_neug_pred_dcs );
[cc_pred_neug_rms, cc_pred_neug_dE] = ...
    color_tool.ref_summary( ...
        cc_ref_src, 'Color Checker Measured', ...
        cc_neug_pred_ref, 'Ramp Neugbauer Predicted',...
        cie.cmf2deg, cie.cmf2deg,...
        cie.illD65, cie.illD65,...
        wp );
    
figure;
subplot(3,1,1), imshow( color_tool.ref2srgbpatches( ...
    cc_ref_src, cie.cmf2deg, cie.illD65, 10, 10, 2, 6, wp) );
title('Measured color checker');
subplot(3,1,2), imshow( color_tool.ref2srgbpatches( ...
    cc_cellular_pred_ref, cie.cmf2deg, cie.illD65, 10, 10, 2, 6, wp) );
title('Cellular color checker');
subplot(3,1,3), imshow( color_tool.ref2srgbpatches( ...
    cc_neug_pred_ref, cie.cmf2deg, cie.illD65, 10, 10, 2, 6, wp) );
title('Neugbauer color checker');

%% PART IV: Predict the Input Ramps
ramp_dc_src = dlmread('.../DataMeasure/PrinterInformation/CMYKRGB02575DC.txt');
ramp_ref_src = dlmread('.../DataMeasure/PrinterInformation/CMYKRGB02575Ref.txt');
ramp_ref_src = color_tool.ref2ref( ...
        ramp_ref_src(:,1:end), ...
        i_nm_min, i_nm_int, i_nm_max, ...
        o_nm_min, o_nm_int, o_nm_max );

ramp_ref_src = ramp_ref_src(:,:);
    
guess_ramp_area = inkjet.spectrum2area_guess( ramp_ref_src );

ramp_cellular_pred_dcs = inkjet.spectrum2dc_cellular( ramp_ref_src, guess_ramp_area );
ramp_cellular_pred_ref = inkjet.dc2spectrum_cellular( ramp_cellular_pred_dcs );
[ramp_pred_cellular_rms, ramp_pred_cellular_dE] = ...
    color_tool.ref_summary( ...
        ramp_ref_src, 'Ramp Measured', ...
        ramp_cellular_pred_ref, 'Ramp Cellular Predicted',...
        cie.cmf2deg, cie.cmf2deg,...
        cie.illD65, cie.illD65,...
        color_tool.ref2xyz(paper_spec, cie.cmf2deg, cie.illD65) );

ramp_neug_pred_dcs = inkjet.spectrum2dc( ramp_ref_src, guess_ramp_area );
ramp_neug_pred_ref = inkjet.dc2spectrum( ramp_neug_pred_dcs );
[ramp_pred_neug_rms, ramp_pred_neug_dE] = ...
    color_tool.ref_summary( ...
        ramp_ref_src, 'Ramp Measured', ...
        ramp_neug_pred_ref, 'Ramp Neugbauer Predicted',...
        cie.cmf2deg, cie.cmf2deg,...
        cie.illD65, cie.illD65,...
        color_tool.ref2xyz(paper_spec, cie.cmf2deg, cie.illD65) );



%% PART V: Predict the Skin DCs
%skin_ref_experiment = skin_ref(1:5,:);
skin_ref_experiment = skin_ref(:,:);

using_pseudo_inv = 1;
if using_pseudo_inv
    guess_skin_areas = inkjet.spectrum2area_guess( skin_ref_experiment );
else
    guess_skin_areas = [0.1 0.5 0.1 0.2 0.1 0 0.1];
%    guess_skin_dcs = load( '.\RESULTS\20090604_PrinterDC\Max_skindc1.txt' );
end

cellular = 1;
if cellular
    skin_pred_dcs = inkjet.spectrum2dc_cellular( skin_ref_experiment, guess_skin_areas);
    skin_pred_ref = inkjet.dc2spectrum_cellular( skin_pred_dcs );
else
    skin_pred_dcs = inkjet.spectrum2dc( skin_ref_experiment, guess_skin_areas);
    skin_pred_ref = inkjet.dc2spectrum( skin_pred_dcs );
end
[skin_pred_rms, skin_pred_dE] = ...
    color_tool.ref_summary( ...
        skin_ref_experiment, 'Skin Measured', ...
        skin_pred_ref, 'Skin Predicted',...
        cie.cmf2deg, cie.cmf2deg,...
        cie.illD65, cie.illD65,...
        color_tool.ref2xyz(paper_spec, cie.cmf2deg, cie.illD65) );


%% Comparing the Printed out result and the Measured result
%reffread = '.\RESULTS\20090605_PrinterDC\HH_skinSpecReadings2.txt';
reffread = './RESULTS/20090611_Cellular/HHPrinterDC4_NeugReadings.txt';
skin_printer_ref = color_tool.ref2ref( ...
        load( reffread ), ...
        i_nm_min, i_nm_int, i_nm_max, ...
        o_nm_min, o_nm_int, o_nm_max );

[skin_printed_rms, skin_printed_dE] = ...
color_tool.ref_summary( ...
    skin_ref_experiment, 'Skin Measured', ...
    skin_printer_ref, 'Skin Printed',...
        cie.cmf2deg, cie.cmf2deg,...
        cie.illD65, cie.illD65,...
        color_tool.ref2xyz(paper_spec, cie.cmf2deg, cie.illD65) );

%% Routine to make a color checker
[Y,I] = sort(sum(skin_ref'));
dark_idx = I(1:24);
% dscc = dark skin color checker
dscc_ref = skin_ref(dark_idx,:);
% Generate a preview image
dscc_img = color_tool.ref2srgbimg(...
    dscc_ref,cie.cmf2deg, cie.illD65,wp,60,60);

guess_dscc_areas = inkjet.spectrum2area_guess( dscc_ref );
dscc_pred_dcs = inkjet.spectrum2dc_cellular( dscc_ref, guess_dscc_areas);
dscc_pred_ref = inkjet.dc2spectrum( dscc_pred_dcs );
dscc_pred_img = color_tool.ref2srgbimg(...
    dscc_pred_ref,cie.cmf2deg, cie.illD65,wp,60,60);

