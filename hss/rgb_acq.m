v = VideoReader('VIDEO6_lo.mp4');
k=0;
isColor=0;
clc;
detectedRed=0;

% Colori ammessi (rosso, verde, blu, giallo, ciano, bianco)
color_set = [255 0 0; 0 255 0; 0 0 255; 255,255,0; 0,255,255; 255 255 255];

while detectedRed<30 && hasFrame(v)
    k=k+1;
    data = readFrame(v);
    
    % Estraiamo la componente rossa
    diff_im = imsubtract(data(:,:,1), rgb2gray(data));
    % Filtro per il rumore
    diff_im = medfilt2(diff_im, [3 3]);
    % Conversione in binary
    diff_im = im2bw(diff_im,0.18);
    
    % Conserviamo i blob di dimensioni maggiori di 300px
    diff_im = bwareaopen(diff_im,300);
    
    % Label sugli oggetti connessi
    bw = bwlabel(diff_im, 8);
    
    % Estraiamo i centroidi
    stats = regionprops(bw, 'BoundingBox', 'Centroid');
    if size(stats,1) > 0
        detectedRed=detectedRed+1;
    end
    imshow(data)
    hold on
    
    k=k+1;
    data = readFrame(v);
end
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

while(hasFrame(v) && RedBoxes>0)
    k=k+1;
    data = readFrame(v);
    
    for obj = 1:length(stats)
        
        
        bcc(obj,:) = stats(obj).Centroid;
        bbb(obj,:) = stats(obj).BoundingBox;
        centroidColumn(obj) = int32(bcc(obj,1)); % "X" value
        centroidRow(obj) = int32(bcc(obj,2)); %"Y" value.
        
        % Estraiamo il valore RGB medio dei 9 pixel adiacenti il centroide
        rgb_center = mean(impixel(data, double(centroidColumn(obj))+x, double(centroidRow(obj))+y),1);
        
        % Calcoliamo l'angolo tra il vettore RGB rilevato e i vettori RGB dei
        % colori ammessi.. consideriamo il colore identificato se forma un
        % angolo inferiore a 25°
        
        ang_thres = 25;
        for i=1:length(color_set)
            ang(i) = acosd(dot(color_set(i,:)/norm(color_set(i,:)),rgb_center/norm(rgb_center)));
        end
        c=find(ang <= ang_thres,1);
        if isempty(c) c=0; end
        detected_in_current(obj)=c;
        
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
            if(tmp_same_color_frames(obj) > 10) % Persiste in 10 frame, quindi è valido
                
                isColor(end+1,obj) = detected_in_current(obj);
                k_color(obj)=size(isColor,1);
                if(detected_in_current(obj)==6) RedBoxes = RedBoxes-1;
                end
                %v.CurrentTime;
                imshow(data)
                
                % Informazioni sul plot
                hold on;
                for obj_=1:length(stats)
                    rectangle('Position',bbb(obj_,:),'EdgeColor','r','LineWidth',2)
                    plot(bcc(obj_,1),bcc(obj_,2), '-m+')
                    
                    a=text(bcc(obj_,1)+15,bcc(obj_,2), strcat('X: ', num2str(round(bcc(obj_,1))), '    Y: ', num2str(round(bcc(obj_,2)))));
                    set(a, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 12, 'Color', 'green');
                end
                pause;
                tmp_same_color_frames(obj)=0;
                tmp_color(obj) = 0;
            end
        end
    end
end

hold off

% Estrazione dei codici
for i=1:length(stats)
    % Estrazione color sequence oggetto corrente
    col_seq = isColor(isColor(:,i)~=0,i);
    % Cerca il primo rosso (sempre prima cifra del codice)
    startp = find(col_seq==1,1);
    % Il bianco è il colore di fine trasmissione
    endp = find(col_seq==6,1);
    
    % Zero-indexed code
    code = col_seq(startp:(endp))-1;
    disp(['# Detected device at ' num2str(centroidColumn(i)) ',' num2str(centroidRow(i)) ' with code ' strcat(num2str(code'))]);
end
