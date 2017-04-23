
a = imaqhwinfo;
tocs=[]; % Vector containing acquisition times
clc;
[camera_name, camera_id, format] = getCameraInfo(a);


if exist('v') 
    stop(v)
    closepreview(v)
end

v = videoinput(camera_name, camera_id, format);
src=getselectedsource(v);

% FUNDAMENTAL: May need to be tweaked according to camera
% Decoding may not work well when using cameras without this parameter
if isprop(src,'Exposure')
    set(src, 'Exposure', -7)
end

% Set the properties of the video object
set(v, 'FramesPerTrigger', Inf);
set(v, 'ReturnedColorspace', 'rgb')
v.FrameGrabInterval = 1;

%start the video aquisition here
start(v)
% preview(v)
k=0;
isColor=0;

detectedRed=0;

% Colori ammessi (blu, rosso, verde, bianco, nero)
color_set = [0 0 255; 255 0 0; 0 255 0; 255 255 255; 0 0 0];
start_color = 1;
end_color=length(color_set);
black_color=end_color;

disp('Searching for device')
while detectedRed<1
    k=k+1;
    data = getsnapshot(v);
%     imshow(data)
 
    % Estraiamo la componente blu
    diff_im = imsubtract(data(:,:,3), rgb2gray(data));
    % Filtro per il rumore
    diff_im = medfilt2(diff_im, [3 3]);
    
    % Conversione in binary
    diff_im = im2bw(diff_im,0.18);
    
    % Conserviamo i blob di dimensioni maggiori di 300px
    diff_im = bwareaopen(diff_im,300);
%     figure
%     imshow(diff_im)
%     jhj
    % Label sugli oggetti connessi
    bw = bwlabel(diff_im, 8);
    
    % Estraiamo i centroidi
    stats = regionprops(bw, 'BoundingBox', 'Centroid');
    if size(stats,1) > 0
        detectedRed=detectedRed+1;
    end

    
end

disp('Got device');
RedBoxes=length(stats);
% Vettori di utilità
x = [-1 0 1 -1 0 1 -1 0 1];
y = [1 1 1 0 0 0 -1 -1 -1];

% Colore temporaneo rilevato
tmp_color=zeros(1,length(stats));
% Numero di frame consecutivi in cui il colore è rilevato
tmp_same_color_frames=zeros(1,length(stats));

isColor=zeros(1,length(stats));
k_color=ones(1,length(stats));

for obj=1:length(stats)
        bcc(obj,:) = stats(obj).Centroid;
        bbb(obj,:) = stats(obj).BoundingBox;
        centroidColumn(obj) = int32(bcc(obj,1)); % "X" value
        centroidRow(obj) = int32(bcc(obj,2)); %"Y" value.
end
tstart=tic;
data = getsnapshot(v);
while(RedBoxes>0)
    k=k+1;
    data = getsnapshot(v);
    tocs(end+1)=toc(tstart)*1000;
    tstart=tic;
    
    for obj = 1:length(stats)

        % Estraiamo il valore RGB medio dei 9 pixel adiacenti il centroide
        rgb_center = mean(impixel(data, double(centroidColumn(obj))+x, double(centroidRow(obj))+y),1);
        
        % Calcoliamo l'angolo tra il vettore RGB rilevato e i vettori RGB dei
        % colori ammessi.. consideriamo il colore identificato se forma un
        % angolo inferiore a 25°
        
        ang_thres = 25;
        for i=1:length(color_set)
            ang(i) = acosd(dot(color_set(i,:)/norm(color_set(i,:)),rgb_center/norm(rgb_center)));
        end
        
        [mi,ind]=min(ang);
        if mi<ang_thres 
            detected_in_current(obj)=ind;
        else detected_in_current(obj)=0;
        end
        if norm(rgb_center)<5
            detected_in_current(obj)=black_color;
        end
        
        % Se c'è un colore in attesa di essere verificato contiamo i frame
        if(tmp_color(obj) ~=0)
            if tmp_color(obj)==detected_in_current(obj) % Il colore rilevato persiste
                tmp_same_color_frames(obj) = tmp_same_color_frames(obj) +1;
            else % Colore non validato
                tmp_same_color_frames(obj) = 0;
                tmp_color(obj) = 0;
            end
        end
        
        % Se l'ultimo colore verificato è diverso dal rilevato
        if isColor(k_color(obj),obj) ~= detected_in_current(obj)
            
            tmp_color(obj) = detected_in_current(obj);
            if(tmp_same_color_frames(obj) >=  2) % Persiste, quindi è valido
                
                isColor(end+1,obj) = detected_in_current(obj);
                k_color(obj)=size(isColor,1);
                if(detected_in_current(obj)==end_color) RedBoxes = RedBoxes-1;
                end

               
                %disp('Rilevata variazione di stato.. Premere un tasto..');
                %pause;
                tmp_same_color_frames(obj)=0;
                tmp_color(obj) = 0;
            end
        end
    end
end

%hold off
stop(v);

% Flush all the image data stored in the memory buffer.
flushdata(v);

% Estrazione dei codici
for i=1:length(stats)
    num=0;
    % Estrazione color sequence oggetto corrente
    col_seq = isColor(isColor(:,i)~=0,i);
    % Cerca il primo blu (sempre prima cifra del codice)
    startp = find(col_seq==start_color,1);
    % Cerca il colore di fine trasmissione
    endp = find(col_seq==end_color,1);
    
    % Zero-indexed code
    code = col_seq((startp+1):(endp-1))-1;
    for j=1:length(code)-1
        num=num+code(j)*4^(j-1);
    end
    checksum = rem(sum(code(1:(end-1))),4);
    
    disp(['# Detected device at ' num2str(centroidColumn(i)) ',' num2str(centroidRow(i)) ' with code ' strcat(num2str(code')) ', num=' num2str(num) ', chk=' num2str(checksum)]);
end
