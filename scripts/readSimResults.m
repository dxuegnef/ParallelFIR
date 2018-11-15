function result = readSimResults(nBitsOutput,n)


    % Import results file content as text
    DataOut_path = '../sim/results/results_DataOut.txt';
    file_DataOut = fopen(DataOut_path,'r');
    txt = textscan(file_DataOut,'%s','delimiter','\n'); 
    txt = cell2mat( txt{1}(12:end,:) );
    
    % Split parallel samples
    odd_samples = txt(:, 1:nBitsOutput);
    even_samples = txt(:, nBitsOutput+1 : end);
    
    DataOut_sample = fi([], true, nBitsOutput, n+n);
    DataOut_samples = zeros(1, 2*length(even_samples), 'like', DataOut_sample);
    for i = 1 : length(even_samples)
        DataOut_sample.bin = strcat( even_samples(i,:) );
        DataOut_samples(2*i-1 + 0) = DataOut_sample;
        
        DataOut_sample.bin = strcat( odd_samples(i,:) );
        DataOut_samples(2*i-1 + 1) = DataOut_sample;
    end
    
    result = DataOut_samples;
    
end