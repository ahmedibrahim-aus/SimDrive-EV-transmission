function resizeFigureAndWait(fig, targetSize)
%RESIZEFIGUREANDWAIT Wait for native window events, not just MATLAB setters.
% Keep this in test infrastructure: the app owns its SizeChangedFcn and must
% receive real events. Never invoke that callback manually to make tests pass.
    fig.WindowState = 'normal';
    drawnow;
    fig.Position = [10 10 targetSize];
    started = tic;
    lastRequest = tic;
    settled = [];
    while toc(started) < 30
        drawnow;
        atTarget = strcmp(fig.WindowState, 'normal') && ...
            all(abs(fig.Position(3:4) - targetSize) <= 1);
        if ~atTarget
            settled = [];
            % A virtual display without a window manager can drop a
            % request; ask again rather than fail on a lost event.
            if toc(lastRequest) > 2
                fig.Position = [10 10 targetSize];
                lastRequest = tic;
            end
        elseif isempty(settled)
            settled = tic;
        elseif toc(settled) >= 0.5
            return;
        end
        pause(0.05);
    end
    error('EVGearbox:Test:ResizeTimeout', ...
        'Window did not settle at %s; actual size is %s.', ...
        mat2str(targetSize), mat2str(fig.Position(3:4)));
end
