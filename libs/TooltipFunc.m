function output_txt = TooltipFunc(~,event_obj)
% ~            Currently not used (empty)
% event_obj    Object containing event data structure
% output_txt   Data cursor text (string or cell array of strings)

eventdata = get(event_obj);
pos = eventdata.Position;

output_txt = {['BT: ' num2str(pos(2)) ]; ['DateStamp: ' datestr(pos(1), 'yyyy-mm-dd HH:MM:SS')]};
%output_txt = pos(1);