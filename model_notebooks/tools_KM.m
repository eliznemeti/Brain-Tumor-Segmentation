function [L,C,LUT]=tools_KM(im,c)
% Segment N-dimensional grayscale image into c classes using a memory 
% efficient implementation of the c-means (aka k-means) clustering 
% algorithm. The computational efficiency is achieved by using the 
% histogram of the image intensities during the clustering process instead 
% of the raw image data.
%
% INPUT ARGUMENTS:
%   - im  : N-dimensional grayscale image in integer format. 
%   - c   : positive interger greater than 1 specifying the number of
%           clusters. c=2 is the default setting. Alternatively, c can be
%           specified as a k-by-1 array of initial cluster (aka prototype)
%           centroids.
%
% OUTPUT  :
%   - L   : label image of the same size as the input image. For example,
%           L==i represents the region associated with prototype C(i),
%           where i=[1,k] (k = number of clusters).
%   - C   : 1-by-k array of cluster centroids.
%   - LUT : L-by-1 array that specifies the intensity-class relations,
%           where L is the dynamic intensity range of the input image. 
%           Specifically, LUT(1) corresponds to class assigned to 
%           min(im(:)) and LUT(L) corresponds to the class assigned to
%           max(im(:)). See 'apply_LUT' function for more info.
%
% Cite:    Anton Semechko (a.semechko@gmail.com)

% Default input arguments
if nargin<2 || isempty(c), c=2; end

% Basic error checking
if nargin<1 || isempty(im)
    error('Insufficient number of input arguments')
end
msg='Revise variable used to specify class centroids. See function documentaion for more info.';
if ~isnumeric(c) || ~isvector(c)
    error(msg)
end
if numel(c)==1 && (~isnumeric(c) || round(c)~=c || c<2)
    error(msg)
end

% Check image format
if isempty(strfind(class(im),'int'))
    error('Input image must be specified in integer format (e.g. uint8, int16)')
end
if sum(isnan(im(:)))~=0 || sum(isinf(im(:)))~=0
    error('Input image contains NaNs or Inf values. Remove them and try again.')
end

% Intensity range
Imin=double(min(im(:)));
Imax=double(max(im(:)));
I=(Imin:Imax)';

% Compute intensity histogram
H=hist(double(im(:)),I);
H=H(:);

% Initialize cluster centroids
if numel(c)>1
    C=c;
    c=numel(c);
else
    dI=(Imax-Imin)/c;
    C=Imin+dI/2:dI:Imax;
end

% Update cluster centroids
IH=I.*H; dC=Inf;
while dC>1E-6
    
    C0=C;
    
    % Distance to the centroids
    D=abs(bsxfun(@minus,I,C));
    
    % Classify by proximity
    [Dmin,LUT]=min(D,[],2); %#ok<*ASGLU>
    for j=1:c
        C(j)=sum(IH(LUT==j))/sum(H(LUT==j));
    end
      
    % Change in centroids 
    dC=max(abs(C-C0));
    
end
L=LUT2label(im,LUT);

function L=LUT2label(im,LUT)
% Create a label image using LUT obtained from a clustering operation of 
% grayscale data.  

% Intensity range
Imin=min(im(:));
Imax=max(im(:));
I=Imin:Imax;

% Create label image
L=zeros(size(im),'uint8');
for k=1:max(LUT)
    
    % Intensity range for k-th class
    i=find(LUT==k);
    i1=i(1);
    if numel(i)>1
        i2=i(end);
    else
        i2=i1;
    end
    
    % Map the intensities in the range [I(i1),I(i2)] to class k 
    bw=im>=I(i1) & im<=I(i2);
    L(bw)=k;
    
end
