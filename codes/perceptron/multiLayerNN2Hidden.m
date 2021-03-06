clear;
clc;
addpath('bin');
data= load_data('k3b', 0.4, 1,0);%k3b.mat k6b.mat l1b.mat


%parameter initialization
Xte=data.Xte;
Xtr=data.Xtr;
Yte=data.Yte;
Ytr=data.Ytr;

frameSize = 128;
hopSize=64;
lowerFr=2;%lowerFr=2;
upperFr=30;%upperFr=257;

%Mu = 3-7, lowerFr=6Hz upperFr=14Hz,  Mu+Beta = 3-15,lowerFr=6Hz upperFr=30Hz ,ony set numbers which are devisible by 2
dataTrain = abs(dostft(Xtr, frameSize, hopSize,'blackman',lowerFr,upperFr));
dataTest =  abs(dostft(Xte, frameSize, hopSize,'blackman',lowerFr,upperFr));

%removing NaN
[dataTrain,Ytr]=removeNaN(dataTrain,Ytr);
[dataTest,Yte]=removeNaN(dataTest,Yte);

%NN parameters
%%%%%Train NN using OXtr%%%%%%%%
X_input = dataTrain; 
Y_label =getOnehotVectorMode(Ytr);
learningRate=0.00005;%learningRate=0.00001; inner layer 35
iterations=100000;%iterations=80000;

parameter=multilayerNeuralNetwork(X_input,Y_label,learningRate,iterations);

X_input = dataTrain;
Ynew =seprateData(parameter,X_input);
%accuracy calculation
acc = accuracyCalc(Y_label,Ynew);
fprintf('Accuracy of the classification using train data : %f \n',acc);

X_input = dataTest;
Ynew =seprateData(parameter,X_input);
Ytest=getOnehotVectorMode(Yte);
%accuracy calculation
acc = accuracyCalc(Ytest,Ynew);
fprintf('Accuracy of the classification using test data : %f \n',acc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%NN functions%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%change labels to one hot vector mode
function y = getOnehotVectorMode(y)
% identify unique classes from labels
[m,n]=size(y);
uniqueLabels = unique(y);
uniqueLabelsSize = length(uniqueLabels);
oneHot=zeros(m,uniqueLabelsSize);
for i = 1:m
    oneHot(i,y(i,n)) = 1;
end
y=oneHot';
end
%multilayer perceptron
function parameter = multilayerNeuralNetwork(Z,y,learningRate,iterations)
% W and B initialization
[m,n] = size(Z);
[p,q] = size(y);
b = ones(1, n);
Z = vertcat(Z,b);
X1 = Z;
middlelayerSize=35;
middlelayer2Size=10;
rng(0);%rng('default');
%1-50 weights for unput features, 51st weight for bias
W1 = normrnd(0,1,middlelayerSize, m+1)*.001;
%1-50 weights for unput features, 51st weight for bias
W2 = normrnd(0,1,middlelayer2Size, middlelayerSize+1)*.001; 
%50 weights for unput to 2nd layer, 51th weight for bias
W3 = normrnd(0,1,p, middlelayer2Size+1)*.001; 

for i=1:iterations
    %forward propagation in 1st layer
    Z1 = W1*X1;%Z1 = W1*X1 + b1;
    X2 = g2(Z1); 
    %Adding bias for 2nd layer
    X2 = vertcat(X2,b); 
    %forward propagation in 2nd layer
    Z2 = W2*X2;% Z2 = W3*X2 + b2;
    X3 = g2(Z2);
    %Adding bias for 3rd layer
    X3 = vertcat(X3,b); 
    %forward propagation in 2nd layer
    Z3 = W3*X3;
    YHat = softMax(Z3);
    % backpropagation in 3rd layer
    dB3 = (YHat - y).*dsoftMax(Z3);%This also works dB3 = (Z3 - y);%
    dW3 = X3*dB3';
    % backpropagation in 2nd layer
    nW3=W3(:,1:size(W3,2)-1);
    dB2 = nW3'*dB3.*dg2(Z2);
    dW2 = X2*dB2';
    % backpropagation in 1st layer
    nW2=W2(:,1:size(W2,2)-1);
    dB1 = nW2'*dB2.*dg2(Z1);
    dW1 = X1*dB1';
    %learning parameters
    W1 = W1-(learningRate*dW1');
    W2 = W2-(learningRate*dW2');
    W3 = W3-(learningRate*dW3');
    %Error calulated as cross entropy:
    error=sum(-sum(y.*log(YHat)));
    fprintf('Iteration : %d, squared error : %f \n',i, error);
    Ynew = getOneHotVec(YHat);
    acc = accuracyCalc(Ynew,y);
    if acc==100.0
        break;
    end
end
parameter.W1 = W1;
parameter.W2 = W2;
parameter.W3 = W3;

end
%seperate Data Function
function Ynew = seprateData(parameter,Z)

[~,n] = size(Z);
b = ones(1, n);
%1st layer bias
Z = vertcat(Z,b);
X1 = Z;
W1=parameter.W1;
W2=parameter.W2;
W3=parameter.W3;
%forward propagation in 1st layer
Z1 = W1*X1;
X2=g2(Z1);
%2ndlayer bias
X2 = vertcat(X2,b);
Z2 = W2*X2;
X3=g2(Z2);
%3rdlayer bias
X3 = vertcat(X3,b);
%forward propagation in 2nd layer
Z3 = W3*X3;
yHat=softMax(Z3);
Ynew = getOneHotVec(yHat);
end
%get Onehot vector
function Ynew = getOneHotVec(Y)
[p,q]=size(Y);
Ynew=zeros(p,q);
for i = 1:q
    [val,index]=max(Y(:,i));
    Ynew(index,i)=1;
end
end

%Accuracy Calulation
function acc = accuracyCalc(Y,yPred)
[m,n]=size(Y);
count=0;
for i=1:n
    count=count+sum((Y(:,i)&yPred(:,i)));
end
acc=count/n*100;
end
%differenctiation of softmax activation
function dsx = dsoftMax(x)
sxij = softMax(x);
dsx=sxij.*(1-sxij);
end
%softmax activation
function sx = softMax(x)   
sx= exp(x)./sum(exp(x));
end
%differenctiation of logistic function
function dgx = dg(x)
dgx = g(x).*(1-g(x));
end
%logistic function
function gx = g(x)
gx = 1.0./(1.0 + exp(-x));
end
%differenctiation of tanh function
function dgx = dg2(x)
dgx =1-g2(x).*g2(x);
end
%tanh function
function gx = g2(x)
gx = tanh(x);
end
