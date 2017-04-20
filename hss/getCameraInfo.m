function [camera_name, camera_id, resolution] = getCameraInfo(a)
% Tweak according to preferred camera settings

camera_name = char(a.InstalledAdaptors(end));
infoimaq=imaqhwinfo(camera_name);
camera_info = infoimaq.DeviceInfo;
camera_info_spec=camera_info(end);
fmt=camera_info_spec.SupportedFormats
camera_id = camera_info_spec.DeviceID;
resolution = char(fmt(11));