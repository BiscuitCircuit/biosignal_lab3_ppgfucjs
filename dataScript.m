clear all
close all 
clc 

data = readtable('ppg_lab3.csv');

data.Properties.VariableNames



time = data{:, 1};
ppgSignal3 = data{:, 3};
ppgSignal4 = data{:, 4};

plot(ppgSignal3)
