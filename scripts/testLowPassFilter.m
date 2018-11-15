function testLowPassFilter
    clc
    close all

    sample_freq = 250e6; % Hz
    sim_time = 1e-5; % Seconds
    
    tone_freq1 = 20e6; % Hz
    tone_freq2 = 100e6; % Hz
    
    % Setup our test data samples
    t = 0:1/sample_freq:sim_time;
    tone1 = cos(2*pi*tone_freq1*t);
    tone2 = cos(2*pi*tone_freq2*t);
    
    rng('default');
    noise = randn(size(t));
    samples = tone1 + tone2 + noise;          

    % Plot the unfiltered data.
    plotPSD(samples,sample_freq,'Unfiltered Data'); 
    
    % Design a low pass filter.
    [coefficients,Hd] = Lowfilter(sample_freq); 
   
    % Filter the data using standard tap chain and matlab generated 
    % coefficent.
    filtered_data_manual = filterManual(samples,coefficients);        
    
    plotPSD(filtered_data_manual,sample_freq,'Basic FIR Filtered Data');   
    
    % Dump out data to facilitate processing in alternative language.            
    dlmwrite('../data/coefficients_float.txt',coefficients,'precision','%1.14f');
    dlmwrite('../data/samples_float.txt',samples,'precision','%1.14f');
    
    
    
    
    % POSSIBLE SOLUTION
    input_data_width = 16;
    output_data_width = 35;
    coefficients_width = 16;
    n = 12;
    
    filtered_data_fpga = filterFPGA(samples, coefficients, input_data_width, output_data_width, coefficients_width, n);
    plotPSD(double(filtered_data_fpga),sample_freq,'Matlab Fi Filtered Data');
    
    % Run the script that handles VHDL simulation
    runSimulationVHDL()
    HDL_simulation_results = readSimResults(output_data_width, n);
    plotPSD(double(HDL_simulation_results),sample_freq,'VHDL Filtered Data');
    
    % Verify that the output from VHDL simulation matches Matlab
    % (verification is also performed in the VHDL testbench itself)
    error_verify = 0;
    for i = 1 : length(HDL_simulation_results)
        if filtered_data_fpga(i) ~= HDL_simulation_results(i)
            fprintf('ERROR, output does not match.')
            error_verify = 1;
        end
    end
    if error_verify == 0
        fprintf('\n\nSUCCESS, VHDL simulation output matches Matlab.\n\n')
    end
    
    
    
    
    % Utility Functions
    
    function plotPSD(samples,sample_freq,title_text)
        nfft = 2^nextpow2(length(samples));
        psd_data = (abs(fft(samples,nfft)).^2)/(length(samples)*sample_freq); 
        figure;        
        Hpsd = dspdata.psd(psd_data(1:length(psd_data)/2),'Fs',sample_freq);            
        plot(Hpsd);        
        title(title_text);
    end

    function [coefficients,Hd] = Lowfilter(sample_freq)        
        
        N     = 8;      % Order
        Fpass = 48e6;   % Passband Frequency
        Fstop = 60e6;   % Stopband Frequency
        Wpass = 1;      % Passband Weight
        Wstop = 1;      % Stopband Weight
        
        % Calculate the coefficients using the FIRLS function.
        coefficients  = firls(N, [0 Fpass Fstop sample_freq/2]/(sample_freq/2), [1 1 0 0], [Wpass Wstop]);
        Hd = dfilt.dffir(coefficients);
    end

    function data_filtered = filterManual(data,coefficients)
        num_taps = length(coefficients)-1;
        data_length = length(data);
        data_filtered_length = data_length - num_taps;
        data_filtered = zeros(1,data_filtered_length);
        for index = 1:data_filtered_length
            data_filtered(index) = sum(data(index:index+num_taps).*coefficients);
        end
    end  
end

