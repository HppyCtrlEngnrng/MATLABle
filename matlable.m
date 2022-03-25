function matlable()
    % reset rng by date(YYYYMMdd) to make 'daily' quiz
    tn = datetime('now', 'TimeZone', 'UTC');
    rng(tn.Year*1e4+tn.Month*1e2+tn.Day);

    % make command dictionary
    cmd_dict = makeCommandDict();

    % generate new figure for game screen
    h_f = figure("Name", "MATLABle");

    h_f.UserData.dict = cmd_dict;
    h_f.UserData.answer = cmd_dict(randi(length(cmd_dict)));
    h_f.UserData.rects = gobjects(6, 5);    % rectangles for cells of letters
    h_f.UserData.guess = gobjects(6, 5);    % texts for user guessed command name

    % place rectangles and texts
    for i_l = 1:5
        for i_c = 1:6
            h_f.UserData.rects(i_c, i_l) = rectangle("Position", [i_l-1,6-i_c,1,1], "FaceColor", [1,1,1]);
            h_f.UserData.guess(i_c, i_l) = text(i_l-1 + 0.5, 6-i_c + 0.5, '', 'HorizontalAlignment','center','VerticalAlignment','middle', 'FontSize', 24, 'FontName', 'Arial Black', 'Color', [0,0,0]);
        end
    end

    % display to show letter identification status
    h_f.UserData.alphabet_disp = gobjects(1, 26);
    alphas = {'abcdefghi', 'jklmnopqr', 'stuvwxyz'};
    for i_l = 1:length(alphas)
        for i_c = 1:length(alphas{i_l})
            h_f.UserData.alphabet_disp(length(alphas{1})*(i_l-1)+i_c) = text(0.5*i_c, -0.25*i_l, alphas{i_l}(i_c), 'HorizontalAlignment','center','VerticalAlignment','middle', 'FontSize', 10, 'FontName', 'Arial Black', 'Color', [0,0,0]);
        end
    end

    % display setting
    set(gca, 'XTickLabel', []);
    set(gca, 'YTickLabel', []);
    set(gca, 'XColor', 'none');
    set(gca, 'YColor', 'none');
    ylim([-1, 6])
    daspect([1,1,1]);

    % letter identification status
    %   (0/1/2/3 for black/gray/yellow/green in wordle)
    h_f.UserData.alphabet_found = zeros(1, 26);
    h_f.UserData.result_color = {[1, 1, 1], [0.6510, 0.6510, 0.6510], [0.9294, 0.6941, 0.1255], [0.3922, 0.8314, 0.0745]};
    % number of attempts
    h_f.UserData.n_attm = 1;

    % start keyboard callback
    h_f.KeyPressFcn = @onKeyClicked;
end

% keyboard callback
function onKeyClicked(o, e)
    % get key
    key = e.Key;

    % switch by key
    if strcmp(key, 'return') % return key
        % not all the letter slots are filled
        if strcmp(o.UserData.guess(o.UserData.n_attm, 5).String, '')
            title("insufficient letters", "Color", [0.8, 0, 0], 'FontName', 'Ariel Black', 'FontSize', 12);
            return;
        end

        % current guess
        guess_t = "";
        for i_c = 1:5
            guess_t = guess_t + o.UserData.guess(o.UserData.n_attm, i_c).String;
        end
        % guessed command is not in the dictionary
        if ~any(o.UserData.dict == guess_t)
            title("command """+guess_t+""" is not found", "Color", [0.8, 0, 0], 'FontName', 'Ariel Black', 'FontSize', 12);
            return;
        end
        % clear error message
        title("", "Color", [0.8, 0, 0], 'FontName', 'Ariel Black', 'FontSize', 12);

        % update display
        for i_c = 1:5
            % green: letter and position is correct
            if o.UserData.answer{1}(i_c) == guess_t{1}(i_c)
                o.UserData.rects(o.UserData.n_attm, i_c).FaceColor = o.UserData.result_color{4};
                o.UserData.alphabet_disp(guess_t{1}(i_c)-'a'+1).Color = o.UserData.result_color{4};
                o.UserData.alphabet_found(guess_t{1}(i_c)-'a'+1) = 4;

            % yellow: letter is correct
            elseif contains(o.UserData.answer{1}, guess_t{1}(i_c))
                o.UserData.rects(o.UserData.n_attm, i_c).FaceColor = o.UserData.result_color{3};
                if (o.UserData.alphabet_found(guess_t{1}(i_c)-'a'+1) < 4)
                    o.UserData.alphabet_disp(guess_t{1}(i_c)-'a'+1).Color = o.UserData.result_color{3};
                    o.UserData.alphabet_found(guess_t{1}(i_c)-'a'+1) = 3;
                end

            % gray: letter is not in the answer
            else
                o.UserData.rects(o.UserData.n_attm, i_c).FaceColor = o.UserData.result_color{2};
                o.UserData.alphabet_disp(guess_t{1}(i_c)-'a'+1).Color = o.UserData.result_color{2};
                o.UserData.alphabet_found(guess_t{1}(i_c)-'a'+1) = 2;
            end
            % make text white after an attempt
            o.UserData.guess(o.UserData.n_attm, i_c).Color = [1,1,1];
        end

        % game end check(correct guess, missed 6-th attempt)
        if o.UserData.answer == guess_t
            title("congratulations! the answer is """ + o.UserData.answer +"""", 'FontName', 'Ariel Black', 'FontSize', 12);
            helptxt = split(help(o.UserData.answer), [newline, newline]);
            disp(helptxt{1});
            o.KeyPressFcn = [];

        elseif o.UserData.n_attm == 6
            title("oops! the answer is """ + o.UserData.answer +"""", "Color", [0.8, 0, 0], 'FontName', 'Ariel Black', 'FontSize', 12);
            helptxt = split(help(o.UserData.answer), [newline, newline]);
            disp(helptxt{1});
            o.KeyPressFcn = [];
        end
        o.UserData.n_attm = o.UserData.n_attm + 1;

    elseif strcmp(key, 'backspace') % backspace key
        % set the last non-blank text to blank
        for i_c = 5:-1:1
            if ~strcmp(o.UserData.guess(o.UserData.n_attm, i_c).String, '')
                o.UserData.guess(o.UserData.n_attm, i_c).String = '';
                break;
            end
        end

    elseif isstrprop(key, 'lower') % lower alphabetic key
        % add to the last blank text object
        for i_c = 1:5
            if strcmp(o.UserData.guess(o.UserData.n_attm, i_c).String, '')
                o.UserData.guess(o.UserData.n_attm, i_c).String = key;
                break;
            end
        end
    end
end

function cmd_dict = makeCommandDict()
    % list MATLAB's search path under matlabroot
    if ispc()
        path_list = string(split(path, ';'));
    else
        path_list = string(split(path, ':'));
    end
    path_list = path_list(startsWith(path_list, matlabroot));

    cmd_dict = cell(length(path_list), 1);
    for i_path = 1:length(path_list)
        % for each path, extract .m files
        files = string(what(path_list(i_path)).m);

        if ~isempty(files)
            % check conditions
            [~, basename] = fileparts(files);
            cmd_dict{i_path} = char( ...
                basename(strlength(basename) == 5 ...
                & cellfun(@all, isstrprop(basename, "lower", "ForceCellOutput",true))));
        end
    end

    cmd_dict = cmd_dict(cellfun(@(C) ~isempty(C), cmd_dict));
    cmd_dict = string(cell2mat(cmd_dict));
    cmd_dict = unique(cmd_dict);
end
