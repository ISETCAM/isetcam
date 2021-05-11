function hPat = cfaDesignUI(nRows, nCols, nColors, wavelength)
%
% Brings up a window that lets you define a periodic CFA with a repeating
% nRows x Cols block and nColors different color filters.
%
% Example:
% If you know the rows and cols you can invoke it this way
%   nRows=3; nCols=3; nColors=3;
%   cfaDesignUI(nRows,nCols,nColors);
%
% If you don't, typing this will bring up a small window to set the rows,
% columns and number of colors
%
% cfaDesignUI
%
%

% TO DO:
%
%  1. See if the import function for individual color filters can be made
%     more inuitive. At this point, when the import radiobutton is selected
%     the user has to go to the side pane to click ok to import a file. May
%     be useful to ave an ok button for each color filter (?)


if (ieNotDefined('nRows') || ieNotDefined('nCols') || ieNotDefined('nColors'))
    init_fig = cfaDesignInit;
    uiwait(init_fig);
    return;
end
if ieNotDefined('wavelength'), wavelength = (380:1068); end


% See if a previous session exists; if so, close it
tmp = findobj('Tag', 'cfaPatternUI');
if ~isempty(tmp), close(tmp); end

% Draw new figure
hPat.fig = figure;
fig_position = get(hPat.fig, 'Position');
fig_width = nColors * 175 + 200;
fig_height = 300;
set(hPat.fig, ...
    'Tag', 'cfaPatternUI', ...
    'NumberTitle', 'Off', ...
    'Resize', 'Off', ...
    'Position', [fig_position(1:2), fig_width, fig_height], ...
    'Name', 'Define CFA pattern and colors', ...
    'Menubar', 'None' ...
    );

% The UI gets hard to read if there are too many colors. IN such cases,
% we let it be resizeable
if nColors >= 5, set(hPat.fig, 'Resize', 'On'); end

% MENU BAR
% UI Menu objects for drop down menus in the figures menubar

hPat.menu_options = uimenu( ... % Options menu
'Parent', hPat.fig, ...
    'Label', 'Options' ...
    );
hPat.menu_save = uimenu( ... % Save CFA option
'Parent', hPat.menu_options, ...
    'Label', 'Save CFA', ...
    'Enable', 'Off', ...
    'Callback', 'cfaDesignCallbacks cfaPattern_save' ...
    );
hPat.menu_view = uimenu( ... % View CFA option
'Parent', hPat.menu_options, ...
    'Label', 'View CFA', ...
    'Enable', 'Off', ...
    'Callback', 'cfaDesignCallbacks cfaPattern_view' ...
    );
hPat.menu_import = uimenu( ... % Reset option
'Parent', hPat.menu_options, ...
    'Label', 'Import', ...
    'Separator', 'On', ...
    'Callback', 'cfaDesignCallbacks cfaPattern_import' ...
    );
hPat.menu_resize = uimenu( ... % Resize option
'Parent', hPat.menu_options, ...
    'Label', 'Resize', ...
    'Callback', 'cfaDesignCallbacks cfaPattern_resize' ...
    );
hPat.menu_reset = uimenu( ... % Reset option
'Parent', hPat.menu_options, ...
    'Label', 'Reset', ...
    'Callback', 'cfaDesignCallbacks cfaPattern_reset' ...
    );
hPat.menu_close = uimenu( ... % Reset option
'Parent', hPat.menu_options, ...
    'Label', 'Close', ...
    'Separator', 'On', ...
    'Callback', 'cfaDesignCallbacks cfaPattern_close' ...
    );
hPat.menu_help = uimenu( ... The Help menu
'Parent', hPat.fig, ...
    'Label', 'Help', ...
    'Callback', 'cfaDesignCallbacks cfaPattern_help' ...
    );

%% MAIN PANEL and SIDE PANEL

hPat.main = uipanel( ... % Main panel
'Parent', hPat.fig, ...
    'Position', [0.005, 0.01, 0.82, 0.98], ...
    'BackgroundColor', get(gcf, 'Color') ...
    );
hPat.side = uipanel( ... % Side panel
'Parent', hPat.fig, ...
    'Position', [0.83, 0.01, 0.165, 0.98], ...
    'BackgroundColor', get(gcf, 'Color') ...
    );

%% SIDE PANEL
% UI objects for the side panels. Includes the axes that shows the CFA and
% the options that control the width and center of color filter
% transmittance curves

hPat.pb_side_done = uicontrol( ... % Done button
'Parent', hPat.side, ...
    'Style', 'pushbutton', ...
    'String', 'Done', ...
    'Units', 'Normalized', ...
    'Position', [0.516, 0.01, 0.45, 0.075], ...
    'BackgroundColor', 'w', ...
    'Callback', 'cfaDesignCallbacks cfaPattern_done', ...
    'KeyPressFcn', 'cfaDesignCallbacks cfaPattern_done' ...
    );
hPat.pb_side_cancel = uicontrol( ... % Cancel button
'Parent', hPat.side, ...
    'Style', 'pushbutton', ...
    'String', 'Cancel', ...
    'Units', 'Normalized', ...
    'Position', [0.033, 0.01, 0.45, 0.075], ...
    'BackgroundColor', 'w', ...
    'Callback', 'cfaDesignCallbacks cfaPattern_cancel', ...
    'KeyPressFcn', 'cfaDesignCallbacks cfaPattern_cancel' ...
    );

hPat.side_panel_cfa = uipanel( ...
    'Parent', hPat.side, ... %     'Title', 'CFA',...
    'Position', [0.005, 0.60, 0.99, 0.39], ...
    'BackgroundColor', get(gcf, 'Color') ...
    );
hPat.side_axes_cfa = axes( ...
    'Parent', hPat.side_panel_cfa, ...
    'Position', [0.01, 0.01, 0.98, 0.98], ...
    'Xtick', [], 'Xcolor', 'w', ...
    'YTick', [], 'Ycolor', 'w' ...
    );

% low level UI objects for the side panel

objHeight = 0.125;

hPat.side_panel_color = uipanel( ... % The color filter panel
'Parent', hPat.side, ...
    'Title', 'Filter 1', ...
    'Fontweight', 'Bold', ...
    'ForegroundColor', 'b', ...
    'Position', [0.005, 0.1, 0.99, 0.5], ...
    'BackgroundColor', get(gcf, 'Color') ...
    );

% Set default currentColor as 1
setappdata(hPat.side_panel_color, 'currentColor', 1);


% PEAK --
hPat.side_static_color_peak = uicontrol( ... % static text - Peak
'Parent', hPat.side_panel_color, ...
    'Style', 'text', ...
    'String', 'Peak', ...
    'HorizontalAlignment', 'Left', ...
    'Units', 'Normalized', ...
    'Position', [0.035, 0.29, 0.3, objHeight], ...
    'ForegroundColor', [0.6, 0.1, 0.1], ...
    'BackgroundColor', get(gcf, 'Color') ...
    );
hPat.side_ed_color_peak = uicontrol( ... % static text - Peak
'Parent', hPat.side_panel_color, ...
    'Style', 'Edit', ...
    'String', '1', ...
    'HorizontalAlignment', 'Right', ...
    'Units', 'Normalized', ...
    'KeyPressFcn', 'cfaDesignCallbacks cfaPattern_peak_ed', ...
    'BackgroundColor', 'w', ...
    'Position', [0.675, 0.31, 0.3, objHeight] ...
    );
hPat.side_slider_color_peak = uicontrol( ... % static text - Peak
'Parent', hPat.side_panel_color, ...
    'Style', 'slider', ...
    'Value', 1, ...
    'HorizontalAlignment', 'Left', ...
    'Units', 'Normalized', ...
    'BackgroundColor', 'w', ...
    'Min', 0, 'Max', 1, ...
    'Callback', 'cfaDesignCallbacks cfaPattern_peak_slider', ...
    'Position', [0.025, 0.175, 0.95, 0.11] ...
    );

% VARIANCE --
hPat.side_static_color_variance = uicontrol( ... % static text - Variance
'Parent', hPat.side_panel_color, ...
    'Style', 'text', ...
    'String', 'Variance', ...
    'HorizontalAlignment', 'Left', ...
    'Units', 'Normalized', ...
    'Position', [0.035, 0.58, 0.5, objHeight], ...
    'ForegroundColor', [0.6, 0.1, 0.1], ...
    'BackgroundColor', get(gcf, 'Color') ...
    );

hPat.side_ed_color_variance = uicontrol( ... % static text - Peak
'Parent', hPat.side_panel_color, ...
    'Style', 'Edit', ...
    'String', '50', ...
    'HorizontalAlignment', 'Right', ...
    'Units', 'Normalized', ...
    'KeyPressFcn', 'cfaDesignCallbacks cfaPattern_variance_ed', ...
    'BackgroundColor', 'w', ...
    'Position', [0.675, 0.6, 0.3, objHeight] ...
    );
hPat.side_slider_color_variance = uicontrol( ... % static text - Peak
'Parent', hPat.side_panel_color, ...
    'Style', 'slider', ...
    'Value', 50, ...
    'HorizontalAlignment', 'Left', ...
    'Units', 'Normalized', ...
    'BackgroundColor', 'w', ...
    'Min', 10, 'Max', 1000, ...
    'Callback', 'cfaDesignCallbacks cfaPattern_variance_slider', ...
    'Position', [0.025, 0.475, 0.95, 0.11] ...
    );

% MEAN --
hPat.side_static_color_mean = uicontrol( ... % static text - Mean
'Parent', hPat.side_panel_color, ...
    'Style', 'text', ...
    'String', 'Mean', ...
    'HorizontalAlignment', 'Left', ...
    'Units', 'Normalized', ...
    'ForegroundColor', [0.6, 0.1, 0.1], ...
    'Position', [0.035, 0.87, 0.3, objHeight], ...
    'BackgroundColor', get(gcf, 'Color') ...
    );

hPat.side_ed_color_mean = uicontrol( ... % static text - Peak
'Parent', hPat.side_panel_color, ...
    'Style', 'Edit', ...
    'String', '600', ...
    'HorizontalAlignment', 'Right', ...
    'Units', 'Normalized', ...
    'BackgroundColor', 'w', ...
    'KeyPressFcn', 'cfaDesignCallbacks cfaPattern_mean_ed', ...
    'Position', [0.675, 0.88, 0.3, objHeight] ...
    );
hPat.side_slider_color_mean = uicontrol( ... % static text - Peak
'Parent', hPat.side_panel_color, ...
    'Style', 'slider', ...
    'Value', 600, ...
    'HorizontalAlignment', 'Left', ...
    'Units', 'Normalized', ...
    'Min', 380, 'Max', 1000, ...
    'BackgroundColor', 'w', ...
    'Callback', 'cfaDesignCallbacks cfaPattern_mean_slider', ...
    'Position', [0.025, 0.76, 0.95, 0.11] ...
    );

hPat.side_color_pb_ok = uicontrol( ...
    'Parent', hPat.side_panel_color, ...
    'Style', 'pushbutton', ...
    'String', 'OK', ...
    'Units', 'Normalized', ...
    'Position', [0.74, 0.015, 0.25, objHeight], ...
    'BackgroundColor', 'w', ...
    'Callback', 'cfaDesignCallbacks color_ok', ...
    'KeyPressFcn', 'cfaDesignCallbacks color_ok' ...
    );


% UI objects for the individual color filters

hPat.colors = struct;
panelHeight = 0.98;
panelWidth = 0.98 / nColors;
panelSpacing = 0.02 / (nColors + 1);

for currentColor = 1:nColors

    hPat.colors(currentColor).points = [];

    xPos = panelSpacing + (currentColor - 1) * (panelWidth + panelSpacing);
    yPos = 0.01;
    hPat.colors(currentColor).main = uipanel( ...
        'Parent', hPat.main, ...
        'Title', sprintf('Filter %d', currentColor), ...
        'Units', 'Normalized', ...
        'Position', [xPos, yPos, panelWidth, panelHeight], ...
        'BackgroundColor', get(gcf, 'Color') ...
        );
    hPat.colors(currentColor).axes = axes( ...
        'Parent', hPat.colors(currentColor).main, ...
        'Position', [0.01, 0.36, 0.98, 0.63], ...
        'ButtonDownFcn', 'cfaDesignCallbacks cfaPattern_color_axes', ...
        'Xtick', [], 'Xcolor', 'w', ...
        'YTick', [], 'Ycolor', 'w' ...
        );
    hPat.colors(currentColor).panel_pattern = uipanel( ...
        'Parent', hPat.colors(currentColor).main, ...
        'Title', 'Pattern', ...
        'Position', [0.01, 0.01, 0.48, 0.33], ...
        'BackgroundColor', get(gcf, 'Color') ...
        );

    % Each color axes should know its own color index, transmittance, and
    % filter order. Stick currentColor as appData to each OK button.
    setappdata(hPat.colors(currentColor).axes, ...
        'currentColor', currentColor);
    % Set default transmittance to the zero vector
    setappdata(hPat.colors(currentColor).axes, ...
        'colorFilter', zeros(length(wavelength), 1));
    % Set default CFa pattern as off everywhere
    setappdata(hPat.colors(currentColor).axes, ...
        'filterOrder', zeros(nRows, nCols, 1));

    % The default selected axes is the axes object for color filter 1
    set(hPat.colors(1).axes, 'Selected', 'On');

    %% Draw panel with color filter drawing options

    % Create the button group.
    hPat.colors(currentColor).colorOptions = uibuttongroup( ...
        'Parent', hPat.colors(currentColor).main, ...
        'Title', 'Color', ...
        'Position', [0.50, 0.01, 0.50, 0.33], ...
        'Visible', 'on', ...
        'SelectionChangeFcn', 'cfaDesignCallbacks cfaPattern_color_option', ...
        'BackgroundColor', get(gcf, 'Color') ...
        );

    % Create three radio buttons in the button group.
    hPat.colors(currentColor).toggleGauss = uicontrol( ...
        'Parent', hPat.colors(currentColor).colorOptions, ...
        'Style', 'Radio', ...
        'String', 'Gaussian', ...
        'Units', 'Normalized', ...
        'Position', [0.025, 0.7, 0.95, 0.2], ...
        'BackgroundColor', get(gcf, 'Color'), ...
        'HandleVisibility', 'off' ...
        );

    hPat.colors(currentColor).togglePulse = uicontrol( ...
        'Parent', hPat.colors(currentColor).colorOptions, ...
        'Style', 'Radio', ...
        'String', 'Pulse', ...
        'Units', 'Normalized', ...
        'Position', [0.025, 0.4, 0.95, 0.2], ...
        'BackgroundColor', get(gcf, 'Color'), ...
        'HandleVisibility', 'off' ...
        );
    hPat.colors(currentColor).toggleImport = uicontrol( ...
        'Parent', hPat.colors(currentColor).colorOptions, ...
        'Style', 'Radio', ...
        'String', 'Import', ...
        'Units', 'Normalized', ...
        'Position', [0.025, 0.1, 0.95, 0.2], ...
        'BackgroundColor', get(gcf, 'Color'), ...
        'HandleVisibility', 'off' ...
        );

    %% Set buttons for points. Each button represents a CFA location
    buttonHeight = 0.8 / nRows;
    buttonWidth = 0.8 / nCols;
    buttonSpacingX = 0.1 / (nCols + 1);
    buttonSpacingY = 0.1 / (nRows + 1);

    for currentRow = 1:nRows
        for currentCol = 1:nCols

            xPos = buttonSpacingX + ...
                (currentCol - 1) * (buttonWidth + buttonSpacingX);
            yPos = buttonSpacingY + ...
                (currentRow - 1) * (buttonHeight + buttonSpacingY);

            pointIndex = sub2ind([nRows, nCols], currentRow, currentCol);

            hPat.colors(currentColor).points(pointIndex) = uicontrol( ...
                'Parent', hPat.colors(currentColor).panel_pattern, ...
                'Style', 'ToggleButton', ...
                'Units', 'normalized', ...
                'Position', [xPos, yPos, buttonWidth, buttonHeight], ...
                'BackgroundColor', 'k', ...
                'Callback', 'cfaDesignCallbacks color_points' ...
                );
            set(hPat.colors(currentColor).points(pointIndex), ...
                'Units', 'Pixels');
            temp = floor(get(hPat.colors(currentColor).points(pointIndex), ...
                'Position'));

            set(hPat.colors(currentColor).points(pointIndex), ...
                'CData', zeros(temp(4), temp(3), 3));
            set(hPat.colors(currentColor).points(pointIndex), ...
                'Units', 'Normalized');

            % Associate each sample point with its own color and its
            % pointIndex. We will need these values later to make sure
            % that color channels are mutually exclusive

            setappdata(hPat.colors(currentColor).points(pointIndex), ...
                'currentColor', currentColor);
            setappdata(hPat.colors(currentColor).points(pointIndex), ...
                'pointIndex', pointIndex);
        end % nCols
    end % nRows


end % nColors

setappdata(hPat.fig, 'handles', hPat);
setappdata(hPat.fig, 'nRows', nRows);
setappdata(hPat.fig, 'nCols', nCols);
setappdata(hPat.fig, 'nColors', nColors);

%Set default for color filters
colorFilters = zeros(length(wavelength), nColors);
setappdata(hPat.fig, 'colorFilters', colorFilters);

return;

%% ------------------------------------------------------------------------
    function init_fig = cfaDesignInit()
        %
        % Get basic cfa information.
        % In a sensor the CFA is periodic.  We specify the rows cols and number of
        % color filters here.  The information is stored in the figure handle
        % structure that we create here.  We return the figure handle structure.
        %

        % If a CFA design window is open, close it and start again
        oldUI = findobj('Tag', 'cfaUI');
        if ~isempty(oldUI), close(oldUI); end

        % Draw a new figure
        init_fig = figure;
        fig_position = get(init_fig, 'Position');
        fig_width = 220;
        fig_height = 130;
        set(init_fig, ...
            'Tag', 'cfaUI', ...
            'NumberTitle', 'Off', ...
            'Resize', 'Off', ...
            'Position', [fig_position(1:2), fig_width, fig_height], ...
            'Name', 'Create custom CFA', ...
            'Menubar', 'None' ...
            );

        % Initialize a handles structure. This will hold all handles from this UI
        h = struct;

        % Make a panel that is parent to all objects that ask intial queries
        h.init = uipanel('Parent', init_fig, ...
            'Position', [0.01, 0.31, 0.98, 0.68], ...
            'BackgroundColor', get(gcf, 'Color') ...
            );
        h.init_static_rows = uicontrol(h.init, ... % Static text
        'Style', 'text', ...
            'String', 'Number of rows:', ...
            'HorizontalAlignment', 'Right', ...
            'FontWeight', 'Bold', ...
            'Units', 'Normalized', ...
            'Position', [0.02, 0.7, 0.7, 0.2], ...
            'BackgroundColor', get(gcf, 'Color') ...
            );
        h.init_static_cols = uicontrol(h.init, ... % Static
        'Style', 'text', ...
            'String', 'Number of columns:', ...
            'HorizontalAlignment', 'Right', ...
            'FontWeight', 'Bold', ...
            'Units', 'Normalized', ...
            'Position', [0.02, 0.4, 0.7, 0.2], ...
            'BackgroundColor', get(gcf, 'Color') ...
            );

        h.init_static_colors = uicontrol(h.init, ... % Static
        'Style', 'text', ...
            'String', 'Number of colors:', ...
            'HorizontalAlignment', 'Right', ...
            'FontWeight', 'Bold', ...
            'Units', 'Normalized', ...
            'Position', [0.02, 0.1, 0.7, 0.2], ...
            'BackgroundColor', get(gcf, 'Color') ...
            );

        h.init_ed_rows = uicontrol(h.init, ... % Editable "Enter filename"
        'Style', 'Edit', ...
            'String', '', ...
            'Units', 'Normalized', ...
            'HorizontalAlignment', 'Right', ...
            'Position', [0.75, 0.72, 0.15, 0.22], ...
            'BackgroundColor', 'w' ...
            );

        h.init_ed_cols = uicontrol(h.init, ... % Editable "Enter filename"
        'Style', 'Edit', ...
            'String', '', ...
            'Units', 'Normalized', ...
            'HorizontalAlignment', 'Right', ...
            'Position', [0.75, 0.42, 0.15, 0.22], ...
            'BackgroundColor', 'w' ...
            );


        h.init_ed_colors = uicontrol(h.init, ... % Editable "Enter filename"
        'Style', 'Edit', ...
            'String', '', ...
            'HorizontalAlignment', 'Right', ...
            'Units', 'Normalized', ...
            'Position', [0.75, 0.12, 0.15, 0.22], ...
            'BackgroundColor', 'w' ...
            );

        h.init_pb_import = uicontrol(init_fig, ... % Editable Import CFA
        'Style', 'pushbutton', ...
            'String', 'Import', ...
            'Units', 'Normalized', ...
            'Position', [0.05, 0.05, 0.25, 0.2], ...
            'BackgroundColor', 'w', ...
            'ForegroundColor', 'b', ...
            'Callback', 'cfaDesignCallbacks cfaPattern_import', ...
            'KeyPressFcn', 'cfaDesignCallbacks cfaPattern_Import' ...
            );

        h.init_pb_cancel = uicontrol(init_fig, ... % Editable "Enter filename"
        'Style', 'pushbutton', ...
            'String', 'Cancel', ...
            'Units', 'Normalized', ...
            'Position', [0.45, 0.05, 0.25, 0.2], ...
            'BackgroundColor', 'w', ...
            'Callback', 'cfaDesignCallbacks init_cancel', ...
            'KeyPressFcn', 'cfaDesignCallbacks init_cancel' ...
            );

        h.init_pb_ok = uicontrol(init_fig, ... % Editable "Enter filename"
        'Style', 'pushbutton', ...
            'String', 'OK', ...
            'Units', 'Normalized', ...
            'Position', [0.725, 0.05, 0.25, 0.2], ...
            'BackgroundColor', 'w', ...
            'Callback', 'cfaDesignCallbacks init_ok', ...
            'KeyPressFcn', 'cfaDesignCallbacks init_ok' ...
            );


        % Stick the handles structure to the figure. Avoids having to pass
        % arguments into callback functions. They can simply use "findobj" to find
        % this figure and pick up info. from the uicontrol objects using the
        % handles

        setappdata(init_fig, 'handles', h)

        return

        % End
