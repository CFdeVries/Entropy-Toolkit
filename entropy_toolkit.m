classdef entropy_toolkit < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        TabGroup                        matlab.ui.container.TabGroup
        voxelbyvoxelentropyTab          matlab.ui.container.Tab
        ButtonGroup                     matlab.ui.container.ButtonGroup
        ApproximateentropyButton        matlab.ui.control.RadioButton
        SampleentropyButton             matlab.ui.control.RadioButton
        FuzzyapproximateentropyButton   matlab.ui.control.RadioButton
        FuzzysampleentropyButton        matlab.ui.control.RadioButton
        CustomButton                    matlab.ui.control.RadioButton
        RunButton                       matlab.ui.control.Button
        selectfMRIfilesButton           matlab.ui.control.Button
        ListBox                         matlab.ui.control.ListBox
        entropyalgorithmLabel           matlab.ui.control.Label
        ButtonGroup_3                   matlab.ui.container.ButtonGroup
        noneButton                      matlab.ui.control.RadioButton
        ButterworthButton               matlab.ui.control.RadioButton
        f1HzEditFieldLabel              matlab.ui.control.Label
        f1HzEditField                   matlab.ui.control.NumericEditField
        f2HzEditFieldLabel              matlab.ui.control.Label
        f2HzEditField                   matlab.ui.control.NumericEditField
        filterorderEditFieldLabel       matlab.ui.control.Label
        filterorderEditField            matlab.ui.control.NumericEditField
        samplingintervalsEditFieldLabel  matlab.ui.control.Label
        samplingintervalsEditField      matlab.ui.control.NumericEditField
        ButtonGroup_4                   matlab.ui.container.ButtonGroup
        highpassButton                  matlab.ui.control.RadioButton
        lowpassButton                   matlab.ui.control.RadioButton
        bandpassButton                  matlab.ui.control.RadioButton
        frequencyfilterLabel            matlab.ui.control.Label
        Panel                           matlab.ui.container.Panel
        rvalueEditFieldLabel            matlab.ui.control.Label
        rvalueEditField                 matlab.ui.control.NumericEditField
        mEditFieldLabel                 matlab.ui.control.Label
        mEditField                      matlab.ui.control.NumericEditField
        tauEditFieldLabel               matlab.ui.control.Label
        tauEditField                    matlab.ui.control.NumericEditField
        discardfirstvolumesEditFieldLabel_2  matlab.ui.control.Label
        discardfirstEditFieldLabel      matlab.ui.control.Label
        discardfirstEditField           matlab.ui.control.NumericEditField
        maskingthresholdEditFieldLabel  matlab.ui.control.Label
        maskingthresholdEditField       matlab.ui.control.NumericEditField
        motionregressionCheckBox        matlab.ui.control.CheckBox
        timescaleEditFieldLabel         matlab.ui.control.Label
        timescaleEditField              matlab.ui.control.EditField
        entropyparametersLabel          matlab.ui.control.Label
        selectadditionalregressorsButton  matlab.ui.control.Button
        ListBox_4                       matlab.ui.control.ListBox
        regionwiseentropyTab            matlab.ui.container.Tab
        ListBox_2                       matlab.ui.control.ListBox
        selectentropyfilesButton        matlab.ui.control.Button
        ListBox_3                       matlab.ui.control.ListBox
        selectiy_niifilesButton         matlab.ui.control.Button
        RunButton_2                     matlab.ui.control.Button
        or_seg8matfilesButton           matlab.ui.control.Button
        checkregistrationButton         matlab.ui.control.Button
        atlasDropDownLabel              matlab.ui.control.Label
        atlasDropDown                   matlab.ui.control.DropDown
    end


    properties (Access = private)
        fMRI
        iy
        seg8
        entropy
        atlas
        regressors
        user_data % Description
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
            FilterButton = app.ButtonGroup_3.SelectedObject;
            app.regressors.ON = 0;
            
            if strcmp(FilterButton.Text, 'none')
                set(app.highpassButton, 'Enable', 'off')
                set(app.lowpassButton, 'Enable', 'off')
                set(app.bandpassButton, 'Enable', 'off')
            end
            
            set(app.f1HzEditField, 'Enable', 'off')
            set(app.f2HzEditField, 'Enable', 'off')
            set(app.filterorderEditField, 'Enable', 'off')
            set(app.samplingintervalsEditField, 'Enable', 'off')
            
            addpath('./algorithms')

        end

        % Button pushed function: RunButton
        function RunButtonPushed(app, event)
        
            tic
            
            r = app.rvalueEditField.Value;
            m = app.mEditField.Value;
            tau = app.tauEditField.Value;
            Ndiscard = app.discardfirstEditField.Value;
            scales = str2double(strsplit(app.timescaleEditField.Value, {',', ' '}));
            TH = app.maskingthresholdEditField.Value;
            
            filter.RT = app.samplingintervalsEditField.Value;
            
            f1 = app.f1HzEditField.Value;
            f2 = app.f2HzEditField.Value;
            
            filter.order = app.filterorderEditField.Value;
            
            if app.ButterworthButton.Value == true
                filter.ON = 1;
                if app.ButtonGroup_4.SelectedObject.Text == 'band-pass'
                    filter.cutoff = [f1 f2];
                    filter.pass = 'bandpass';
                else
                    filter.cutoff = f1;
                    filter.pass = app.ButtonGroup_4.SelectedObject.Text(1:end-5);
                end
                [filter.b, filter.a] = butter(filter.order, filter.cutoff.*2.*filter.RT, filter.pass);
            else
                filter.ON = 0;
            end
            
            
            % entropy algorithm selection           
            if app.ApproximateentropyButton.Value == true
                algorithm = 'ApEn';
            elseif app.SampleentropyButton.Value == true
                algorithm = 'SampEn';
            elseif app.FuzzyapproximateentropyButton.Value == true
                algorithm = 'fApEn';
            elseif app.FuzzysampleentropyButton.Value == true
                algorithm = 'fSampEn';
            elseif app.CustomButton.Value == true
                algorithm = 'custom';
            end
            
            
            d = uiprogressdlg(app.UIFigure,'Title','Please Wait',...
        'Message','Running');
                

            fMRI.path = app.fMRI.path;
            Nfiles = size(app.fMRI.name, 1);
            
            regressors.motion.ON = app.motionregressionCheckBox.Value;
            regressors.add.ON = app.regressors.ON;

            if app.regressors.ON == 1
                Nregressors = size(app.regressors.name, 1);
                if Nfiles ~= Nregressors
                    error('Number of fMRI files is not equal to the number of regressor files');
                end
            end
            
            
            for i = 1:Nfiles
                fMRI.name = app.fMRI.name(i,:);
                d.Message = ['Calculating entropy for ', fMRI.name];
                
                if app.regressors.ON == 1
                    regressors.add.fullpath = app.regressors.fullpath(i, :);
                end
                
                entropy_whole_brain(m, tau, r, fMRI, filter, regressors, scales, algorithm, Ndiscard, TH);
                
                d.Value = d.Value + 1/Nfiles;
            end
            
            toc
            
            if regressors.motion.ON
                calc_motion(app.fMRI);
            end

        end

        % Button pushed function: selectfMRIfilesButton
        function selectfMRIfilesButtonPushed(app, event)
            [app.fMRI.name, app.fMRI.path] = uigetfile('*.nii', 'MultiSelect', 'on');
            if ~isequal(app.fMRI.name, 0)
                if ~iscell(app.fMRI.name)
                    app.fMRI.name = {app.fMRI.name};
                end
                app.ListBox.Items = app.fMRI.name;
                app.fMRI.name = char(app.fMRI.name);
            end
        end

        % Selection changed function: ButtonGroup_3
        function ButtonGroup_3SelectionChanged(app, event)
            
            selectedButton = app.ButtonGroup_3.SelectedObject;
            
            if ~strcmp(selectedButton.Text, 'none')
                set(app.highpassButton, 'Enable', 'on')
                set(app.lowpassButton, 'Enable', 'on')
                set(app.highpassButton, 'Enable', 'on')
                set(app.f1HzEditField, 'Enable', 'on')
                set(app.filterorderEditField, 'Enable', 'on')
                set(app.samplingintervalsEditField, 'Enable', 'on')
            elseif strcmp(selectedButton.Text, 'none')
                set(app.highpassButton, 'Enable', 'off')
                set(app.lowpassButton, 'Enable', 'off')
                set(app.highpassButton, 'Enable', 'off')
                set(app.f1HzEditField, 'Enable', 'off')
                set(app.f2HzEditField, 'Enable', 'off')
                set(app.filterorderEditField, 'Enable', 'off')
                set(app.samplingintervalsEditField, 'Enable', 'off')
            end
                
        end

        % Selection changed function: ButtonGroup_4
        function ButtonGroup_4SelectionChanged(app, event)
            selectedButton = app.ButtonGroup_4.SelectedObject;
            
            if strcmp(selectedButton.Text, 'band-pass')
                set(app.f2HzEditField, 'Enable', 'on')
            else
                set(app.f2HzEditField, 'Enable', 'off')
            end
        end

        % Button pushed function: selectiy_niifilesButton
        function selectiy_niifilesButtonPushed(app, event)
            [app.iy.name, app.iy.path] = uigetfile('iy_*.nii', 'MultiSelect', 'on');
            app.iy.fullpath = fullfile(app.iy.path, app.iy.name);
            if ~isequal(app.iy.name, 0)
                if ~iscell(app.iy.name)
                    app.iy.name = {app.iy.name};
                    app.iy.fullpath = {app.iy.fullpath};
                end
                app.ListBox_3.Items = app.iy.name;
                app.iy.name = char(app.iy.name);
                app.seg8 = [];
            end
        end

        % Button pushed function: selectentropyfilesButton
        function selectentropyfilesButtonPushed(app, event)
            [app.entropy.name, app.entropy.path] = uigetfile('*.nii', 'MultiSelect', 'on');
            app.entropy.fullpath = fullfile(app.entropy.path, app.entropy.name);
            if ~isequal(app.entropy.name, 0)
                if ~iscell(app.entropy.name)
                    app.entropy.name = {app.entropy.name};
                    app.entropy.fullpath = {app.entropy.fullpath};
                end
                app.ListBox_2.Items = app.entropy.name;
                app.entropy.name = char(app.entropy.name);
            end
        end

        % Button pushed function: RunButton_2
        function RunButton_2Pushed(app, event)
        
            Nentropy = size(app.entropy.name, 1);
        
            if ~isempty(app.seg8)
                Nseg8 = size(app.seg8.name, 1);
                
                if Nentropy ~= Nseg8
                    error('Number of entropy files is not equal to the number of *_seg8.mat files');
                end
                
                app.iy.fullpath = generate_iy_files(app.seg8);
            end
                
            if ~isempty(app.iy) && ~isempty(app.entropy)
                Niy = size(app.iy.name, 1);
                
                if Nentropy ~= Niy
                    error('Number of entropy files is not equal to the number of iy_*.nii files');
                end
                                
                MNI_atlas = app.atlasDropDown.Value;
                app.atlas.fullpath = atlas_to_native_space(app.entropy, app.iy.fullpath, MNI_atlas);
            end
            
            if ~isempty(app.entropy) && ~isempty(app.atlas)
                calc_avg_entropy(app.entropy.fullpath, app.atlas.fullpath, MNI_atlas);
            end            
        end

        % Button pushed function: or_seg8matfilesButton
        function or_seg8matfilesButtonPushed(app, event)
            [app.seg8.name, app.seg8.path] = uigetfile('*_seg8.mat', 'MultiSelect', 'on');
            if ~isequal(app.seg8.name, 0)
                if ~iscell(app.seg8.name)
                    app.seg8.name = {app.seg8.name};
                end
                app.ListBox_3.Items = app.seg8.name;
                app.seg8.name = char(app.seg8.name);
                app.iy = [];
            end
        end

        % Button pushed function: checkregistrationButton
        function checkregistrationButtonPushed(app, event)
            if ~isempty(app.entropy) && ~isempty(app.atlas)
                check_reg(app.entropy.fullpath, app.atlas.fullpath)
            end
        end

        % Button pushed function: selectadditionalregressorsButton
        function selectadditionalregressorsButtonPushed(app, event)
            [app.regressors.name, app.regressors.path] = uigetfile({'*.txt';'*.mat'}, 'MultiSelect', 'on');
            app.regressors.fullpath = fullfile(app.regressors.path, app.regressors.name);
            
            if ~isequal(app.regressors.name, 0)
                if ~iscell(app.regressors.name)
                    app.regressors.name = {app.regressors.name};
                end
                app.ListBox_4.Items = app.regressors.name;
                app.regressors.name = char(app.regressors.name);
                app.regressors.ON = 1;
            else
                app.regressors.ON = 0;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [1 1 0.9216];
            app.UIFigure.Position = [100 100 716 581];
            app.UIFigure.Name = 'Entropy Toolkit v0.1-beta';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 716 581];

            % Create voxelbyvoxelentropyTab
            app.voxelbyvoxelentropyTab = uitab(app.TabGroup);
            app.voxelbyvoxelentropyTab.Title = 'voxel-by-voxel entropy';

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.voxelbyvoxelentropyTab);
            app.ButtonGroup.TitlePosition = 'centertop';
            app.ButtonGroup.BackgroundColor = [0.8902 0.8902 0.9608];
            app.ButtonGroup.FontName = 'Arial';
            app.ButtonGroup.FontWeight = 'bold';
            app.ButtonGroup.FontSize = 14;
            app.ButtonGroup.Position = [40 372 211 148];

            % Create ApproximateentropyButton
            app.ApproximateentropyButton = uiradiobutton(app.ButtonGroup);
            app.ApproximateentropyButton.Text = 'Approximate entropy';
            app.ApproximateentropyButton.FontName = 'Arial';
            app.ApproximateentropyButton.FontSize = 14;
            app.ApproximateentropyButton.Position = [11 115 151 22];
            app.ApproximateentropyButton.Value = true;

            % Create SampleentropyButton
            app.SampleentropyButton = uiradiobutton(app.ButtonGroup);
            app.SampleentropyButton.Text = 'Sample entropy';
            app.SampleentropyButton.FontName = 'Arial';
            app.SampleentropyButton.FontSize = 14;
            app.SampleentropyButton.Position = [11 88 120 22];

            % Create FuzzyapproximateentropyButton
            app.FuzzyapproximateentropyButton = uiradiobutton(app.ButtonGroup);
            app.FuzzyapproximateentropyButton.Text = 'Fuzzy approximate entropy';
            app.FuzzyapproximateentropyButton.FontName = 'Arial';
            app.FuzzyapproximateentropyButton.FontSize = 14;
            app.FuzzyapproximateentropyButton.Position = [11 62 192 22];

            % Create FuzzysampleentropyButton
            app.FuzzysampleentropyButton = uiradiobutton(app.ButtonGroup);
            app.FuzzysampleentropyButton.Text = 'Fuzzy sample entropy';
            app.FuzzysampleentropyButton.FontName = 'Arial';
            app.FuzzysampleentropyButton.FontSize = 14;
            app.FuzzysampleentropyButton.Position = [11 34 159 22];

            % Create CustomButton
            app.CustomButton = uiradiobutton(app.ButtonGroup);
            app.CustomButton.Text = 'Custom';
            app.CustomButton.FontName = 'Arial';
            app.CustomButton.FontSize = 14;
            app.CustomButton.FontColor = [0.7686 0.0784 0.5059];
            app.CustomButton.Position = [11 8 70 22];

            % Create RunButton
            app.RunButton = uibutton(app.voxelbyvoxelentropyTab, 'push');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);
            app.RunButton.BackgroundColor = [0.8863 0.8941 0.9647];
            app.RunButton.FontSize = 14;
            app.RunButton.Position = [84 19 100 24];
            app.RunButton.Text = 'Run';

            % Create selectfMRIfilesButton
            app.selectfMRIfilesButton = uibutton(app.voxelbyvoxelentropyTab, 'push');
            app.selectfMRIfilesButton.ButtonPushedFcn = createCallbackFcn(app, @selectfMRIfilesButtonPushed, true);
            app.selectfMRIfilesButton.BackgroundColor = [0.8863 0.8941 0.9647];
            app.selectfMRIfilesButton.FontName = 'Arial';
            app.selectfMRIfilesButton.FontSize = 14;
            app.selectfMRIfilesButton.Position = [417 334 127 28];
            app.selectfMRIfilesButton.Text = 'select fMRI file(s)';

            % Create ListBox
            app.ListBox = uilistbox(app.voxelbyvoxelentropyTab);
            app.ListBox.Items = {'->', '', '', ''};
            app.ListBox.Position = [278 209 405 112];
            app.ListBox.Value = '->';

            % Create entropyalgorithmLabel
            app.entropyalgorithmLabel = uilabel(app.voxelbyvoxelentropyTab);
            app.entropyalgorithmLabel.FontSize = 14;
            app.entropyalgorithmLabel.FontWeight = 'bold';
            app.entropyalgorithmLabel.Position = [83 522 125 22];
            app.entropyalgorithmLabel.Text = 'entropy algorithm';

            % Create ButtonGroup_3
            app.ButtonGroup_3 = uibuttongroup(app.voxelbyvoxelentropyTab);
            app.ButtonGroup_3.SelectionChangedFcn = createCallbackFcn(app, @ButtonGroup_3SelectionChanged, true);
            app.ButtonGroup_3.TitlePosition = 'centertop';
            app.ButtonGroup_3.BackgroundColor = [0.8902 0.8902 0.9608];
            app.ButtonGroup_3.FontWeight = 'bold';
            app.ButtonGroup_3.FontSize = 14;
            app.ButtonGroup_3.Position = [278 388 405 132];

            % Create noneButton
            app.noneButton = uiradiobutton(app.ButtonGroup_3);
            app.noneButton.Text = 'none';
            app.noneButton.FontSize = 14;
            app.noneButton.Position = [11 101 53 22];
            app.noneButton.Value = true;

            % Create ButterworthButton
            app.ButterworthButton = uiradiobutton(app.ButtonGroup_3);
            app.ButterworthButton.Text = 'Butterworth';
            app.ButterworthButton.FontSize = 14;
            app.ButterworthButton.Position = [11 74 94 22];

            % Create f1HzEditFieldLabel
            app.f1HzEditFieldLabel = uilabel(app.ButtonGroup_3);
            app.f1HzEditFieldLabel.HorizontalAlignment = 'right';
            app.f1HzEditFieldLabel.FontSize = 14;
            app.f1HzEditFieldLabel.Position = [219 105 112 22];
            app.f1HzEditFieldLabel.Text = 'f1 [Hz]';

            % Create f1HzEditField
            app.f1HzEditField = uieditfield(app.ButtonGroup_3, 'numeric');
            app.f1HzEditField.Limits = [0 Inf];
            app.f1HzEditField.Position = [346 105 48 22];

            % Create f2HzEditFieldLabel
            app.f2HzEditFieldLabel = uilabel(app.ButtonGroup_3);
            app.f2HzEditFieldLabel.HorizontalAlignment = 'right';
            app.f2HzEditFieldLabel.FontSize = 14;
            app.f2HzEditFieldLabel.Position = [219 73 112 22];
            app.f2HzEditFieldLabel.Text = 'f2 [Hz]';

            % Create f2HzEditField
            app.f2HzEditField = uieditfield(app.ButtonGroup_3, 'numeric');
            app.f2HzEditField.Limits = [0 Inf];
            app.f2HzEditField.Position = [346 73 48 22];

            % Create filterorderEditFieldLabel
            app.filterorderEditFieldLabel = uilabel(app.ButtonGroup_3);
            app.filterorderEditFieldLabel.HorizontalAlignment = 'right';
            app.filterorderEditFieldLabel.FontSize = 14;
            app.filterorderEditFieldLabel.Position = [219 40 112 22];
            app.filterorderEditFieldLabel.Text = 'filter order';

            % Create filterorderEditField
            app.filterorderEditField = uieditfield(app.ButtonGroup_3, 'numeric');
            app.filterorderEditField.Limits = [0 Inf];
            app.filterorderEditField.ValueDisplayFormat = '%.0f';
            app.filterorderEditField.Position = [346 40 48 22];

            % Create samplingintervalsEditFieldLabel
            app.samplingintervalsEditFieldLabel = uilabel(app.ButtonGroup_3);
            app.samplingintervalsEditFieldLabel.HorizontalAlignment = 'right';
            app.samplingintervalsEditFieldLabel.FontSize = 14;
            app.samplingintervalsEditFieldLabel.Position = [219 9 112 22];
            app.samplingintervalsEditFieldLabel.Text = 'repetition time [s]';

            % Create samplingintervalsEditField
            app.samplingintervalsEditField = uieditfield(app.ButtonGroup_3, 'numeric');
            app.samplingintervalsEditField.Limits = [0 Inf];
            app.samplingintervalsEditField.Position = [346 9 48 22];

            % Create ButtonGroup_4
            app.ButtonGroup_4 = uibuttongroup(app.ButtonGroup_3);
            app.ButtonGroup_4.SelectionChangedFcn = createCallbackFcn(app, @ButtonGroup_4SelectionChanged, true);
            app.ButtonGroup_4.BorderType = 'none';
            app.ButtonGroup_4.BackgroundColor = [0.8902 0.8902 0.9608];
            app.ButtonGroup_4.Position = [118 39 113 88];

            % Create highpassButton
            app.highpassButton = uiradiobutton(app.ButtonGroup_4);
            app.highpassButton.Text = 'high-pass';
            app.highpassButton.FontSize = 14;
            app.highpassButton.Position = [11 62 83 22];
            app.highpassButton.Value = true;

            % Create lowpassButton
            app.lowpassButton = uiradiobutton(app.ButtonGroup_4);
            app.lowpassButton.Text = 'low-pass';
            app.lowpassButton.FontSize = 14;
            app.lowpassButton.Position = [11 37 77 22];

            % Create bandpassButton
            app.bandpassButton = uiradiobutton(app.ButtonGroup_4);
            app.bandpassButton.Text = 'band-pass';
            app.bandpassButton.FontSize = 14;
            app.bandpassButton.Position = [11 12 87 22];

            % Create frequencyfilterLabel
            app.frequencyfilterLabel = uilabel(app.voxelbyvoxelentropyTab);
            app.frequencyfilterLabel.FontSize = 14;
            app.frequencyfilterLabel.FontWeight = 'bold';
            app.frequencyfilterLabel.Position = [427 522 107 22];
            app.frequencyfilterLabel.Text = 'frequency filter';

            % Create Panel
            app.Panel = uipanel(app.voxelbyvoxelentropyTab);
            app.Panel.BackgroundColor = [0.8902 0.8902 0.9608];
            app.Panel.Position = [40 67 211 269];

            % Create rvalueEditFieldLabel
            app.rvalueEditFieldLabel = uilabel(app.Panel);
            app.rvalueEditFieldLabel.HorizontalAlignment = 'right';
            app.rvalueEditFieldLabel.FontSize = 14;
            app.rvalueEditFieldLabel.Position = [44 233 48 22];
            app.rvalueEditFieldLabel.Text = 'r-value';

            % Create rvalueEditField
            app.rvalueEditField = uieditfield(app.Panel, 'numeric');
            app.rvalueEditField.Limits = [0 Inf];
            app.rvalueEditField.FontSize = 14;
            app.rvalueEditField.Position = [119 233 51 22];
            app.rvalueEditField.Value = 0.25;

            % Create mEditFieldLabel
            app.mEditFieldLabel = uilabel(app.Panel);
            app.mEditFieldLabel.HorizontalAlignment = 'center';
            app.mEditFieldLabel.FontSize = 14;
            app.mEditFieldLabel.Position = [50 205 42 22];
            app.mEditFieldLabel.Text = 'm';

            % Create mEditField
            app.mEditField = uieditfield(app.Panel, 'numeric');
            app.mEditField.Limits = [1 Inf];
            app.mEditField.ValueDisplayFormat = '%.0f';
            app.mEditField.FontSize = 14;
            app.mEditField.Position = [119 205 51 22];
            app.mEditField.Value = 2;

            % Create tauEditFieldLabel
            app.tauEditFieldLabel = uilabel(app.Panel);
            app.tauEditFieldLabel.HorizontalAlignment = 'center';
            app.tauEditFieldLabel.FontSize = 14;
            app.tauEditFieldLabel.Position = [50 176 42 22];
            app.tauEditFieldLabel.Text = 'tau';

            % Create tauEditField
            app.tauEditField = uieditfield(app.Panel, 'numeric');
            app.tauEditField.ValueDisplayFormat = '%.0f';
            app.tauEditField.FontSize = 14;
            app.tauEditField.Position = [119 176 51 22];
            app.tauEditField.Value = 1;

            % Create discardfirstvolumesEditFieldLabel_2
            app.discardfirstvolumesEditFieldLabel_2 = uilabel(app.Panel);
            app.discardfirstvolumesEditFieldLabel_2.HorizontalAlignment = 'right';
            app.discardfirstvolumesEditFieldLabel_2.FontSize = 14;
            app.discardfirstvolumesEditFieldLabel_2.Position = [138 93 58 22];
            app.discardfirstvolumesEditFieldLabel_2.Text = 'volumes';

            % Create discardfirstEditFieldLabel
            app.discardfirstEditFieldLabel = uilabel(app.Panel);
            app.discardfirstEditFieldLabel.HorizontalAlignment = 'right';
            app.discardfirstEditFieldLabel.FontSize = 14;
            app.discardfirstEditFieldLabel.Position = [19 93 77 22];
            app.discardfirstEditFieldLabel.Text = 'discard first';

            % Create discardfirstEditField
            app.discardfirstEditField = uieditfield(app.Panel, 'numeric');
            app.discardfirstEditField.FontSize = 14;
            app.discardfirstEditField.Position = [105 93 33 22];
            app.discardfirstEditField.Value = 5;

            % Create maskingthresholdEditFieldLabel
            app.maskingthresholdEditFieldLabel = uilabel(app.Panel);
            app.maskingthresholdEditFieldLabel.HorizontalAlignment = 'right';
            app.maskingthresholdEditFieldLabel.FontSize = 14;
            app.maskingthresholdEditFieldLabel.Position = [18 54 119 22];
            app.maskingthresholdEditFieldLabel.Text = 'masking threshold';

            % Create maskingthresholdEditField
            app.maskingthresholdEditField = uieditfield(app.Panel, 'numeric');
            app.maskingthresholdEditField.Limits = [0 Inf];
            app.maskingthresholdEditField.FontSize = 14;
            app.maskingthresholdEditField.Position = [151 54 45 22];
            app.maskingthresholdEditField.Value = 0.8;

            % Create motionregressionCheckBox
            app.motionregressionCheckBox = uicheckbox(app.Panel);
            app.motionregressionCheckBox.Text = 'motion regression';
            app.motionregressionCheckBox.FontSize = 14;
            app.motionregressionCheckBox.Position = [41 14 133 22];
            app.motionregressionCheckBox.Value = true;

            % Create timescaleEditFieldLabel
            app.timescaleEditFieldLabel = uilabel(app.Panel);
            app.timescaleEditFieldLabel.HorizontalAlignment = 'center';
            app.timescaleEditFieldLabel.FontSize = 14;
            app.timescaleEditFieldLabel.Position = [36.5 144 69 22];
            app.timescaleEditFieldLabel.Text = 'time scale';

            % Create timescaleEditField
            app.timescaleEditField = uieditfield(app.Panel, 'text');
            app.timescaleEditField.HorizontalAlignment = 'right';
            app.timescaleEditField.Position = [118 144 51 22];
            app.timescaleEditField.Value = '1';

            % Create entropyparametersLabel
            app.entropyparametersLabel = uilabel(app.voxelbyvoxelentropyTab);
            app.entropyparametersLabel.FontSize = 14;
            app.entropyparametersLabel.FontWeight = 'bold';
            app.entropyparametersLabel.Position = [78 338 136 22];
            app.entropyparametersLabel.Text = 'entropy parameters';

            % Create selectadditionalregressorsButton
            app.selectadditionalregressorsButton = uibutton(app.voxelbyvoxelentropyTab, 'push');
            app.selectadditionalregressorsButton.ButtonPushedFcn = createCallbackFcn(app, @selectadditionalregressorsButtonPushed, true);
            app.selectadditionalregressorsButton.BackgroundColor = [0.8863 0.8941 0.9647];
            app.selectadditionalregressorsButton.FontName = 'Arial';
            app.selectadditionalregressorsButton.FontSize = 14;
            app.selectadditionalregressorsButton.Position = [388 162 186 28];
            app.selectadditionalregressorsButton.Text = 'select additional regressors';

            % Create ListBox_4
            app.ListBox_4 = uilistbox(app.voxelbyvoxelentropyTab);
            app.ListBox_4.Items = {'->', '', '', ''};
            app.ListBox_4.Position = [278 37 405 112];
            app.ListBox_4.Value = '->';

            % Create regionwiseentropyTab
            app.regionwiseentropyTab = uitab(app.TabGroup);
            app.regionwiseentropyTab.Title = 'region-wise entropy';

            % Create ListBox_2
            app.ListBox_2 = uilistbox(app.regionwiseentropyTab);
            app.ListBox_2.Items = {'->', '', '', ''};
            app.ListBox_2.Position = [29 308 405 173];
            app.ListBox_2.Value = '->';

            % Create selectentropyfilesButton
            app.selectentropyfilesButton = uibutton(app.regionwiseentropyTab, 'push');
            app.selectentropyfilesButton.ButtonPushedFcn = createCallbackFcn(app, @selectentropyfilesButtonPushed, true);
            app.selectentropyfilesButton.BackgroundColor = [0.8902 0.8902 0.9608];
            app.selectentropyfilesButton.FontName = 'Arial';
            app.selectentropyfilesButton.FontSize = 14;
            app.selectentropyfilesButton.Position = [161 497 141 28];
            app.selectentropyfilesButton.Text = 'select entropy file(s)';

            % Create ListBox_3
            app.ListBox_3 = uilistbox(app.regionwiseentropyTab);
            app.ListBox_3.Items = {'->', '', '', ''};
            app.ListBox_3.Position = [29 61 405 173];
            app.ListBox_3.Value = '->';

            % Create selectiy_niifilesButton
            app.selectiy_niifilesButton = uibutton(app.regionwiseentropyTab, 'push');
            app.selectiy_niifilesButton.ButtonPushedFcn = createCallbackFcn(app, @selectiy_niifilesButtonPushed, true);
            app.selectiy_niifilesButton.BackgroundColor = [0.8863 0.8941 0.9647];
            app.selectiy_niifilesButton.FontName = 'Arial';
            app.selectiy_niifilesButton.FontSize = 14;
            app.selectiy_niifilesButton.Position = [74 250 141 28];
            app.selectiy_niifilesButton.Text = 'select iy_*.nii file(s)';

            % Create RunButton_2
            app.RunButton_2 = uibutton(app.regionwiseentropyTab, 'push');
            app.RunButton_2.ButtonPushedFcn = createCallbackFcn(app, @RunButton_2Pushed, true);
            app.RunButton_2.BackgroundColor = [0.8863 0.8941 0.9647];
            app.RunButton_2.FontSize = 14;
            app.RunButton_2.Position = [453 61 100 24];
            app.RunButton_2.Text = 'Run';

            % Create or_seg8matfilesButton
            app.or_seg8matfilesButton = uibutton(app.regionwiseentropyTab, 'push');
            app.or_seg8matfilesButton.ButtonPushedFcn = createCallbackFcn(app, @or_seg8matfilesButtonPushed, true);
            app.or_seg8matfilesButton.BackgroundColor = [0.8863 0.8941 0.9647];
            app.or_seg8matfilesButton.FontName = 'Arial';
            app.or_seg8matfilesButton.FontSize = 14;
            app.or_seg8matfilesButton.Position = [252 250 141 28];
            app.or_seg8matfilesButton.Text = 'or *_seg8.mat file(s)';

            % Create checkregistrationButton
            app.checkregistrationButton = uibutton(app.regionwiseentropyTab, 'push');
            app.checkregistrationButton.ButtonPushedFcn = createCallbackFcn(app, @checkregistrationButtonPushed, true);
            app.checkregistrationButton.BackgroundColor = [0.8863 0.8941 0.9647];
            app.checkregistrationButton.FontSize = 14;
            app.checkregistrationButton.Position = [572 61 130 24];
            app.checkregistrationButton.Text = 'check registration';

            % Create atlasDropDownLabel
            app.atlasDropDownLabel = uilabel(app.regionwiseentropyTab);
            app.atlasDropDownLabel.HorizontalAlignment = 'right';
            app.atlasDropDownLabel.FontSize = 14;
            app.atlasDropDownLabel.Position = [516 497 35 22];
            app.atlasDropDownLabel.Text = 'atlas';

            % Create atlasDropDown
            app.atlasDropDown = uidropdown(app.regionwiseentropyTab);
            app.atlasDropDown.Items = {'AAL', 'AAL2', 'AAL3'};
            app.atlasDropDown.FontSize = 14;
            app.atlasDropDown.BackgroundColor = [0.8902 0.8902 0.9608];
            app.atlasDropDown.Position = [566 497 100 22];
            app.atlasDropDown.Value = 'AAL';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = entropy_toolkit

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end