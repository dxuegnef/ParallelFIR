function filtered_data_fpga = filterFPGA(data, coefficients, input_data_width, output_data_width, coefficients_width, n)
        data_fi = fi(data, true, input_data_width, n);
        coefficients_fi = fi(coefficients, true, coefficients_width, n);
                
        num_taps = length(coefficients);
        data_length = length(data);
        data_filtered_length = data_length - num_taps;
        
        max_width = (input_data_width + coefficients_width + num_taps-1);
        full_width_sample = fi([], true, max_width, n+n);
        full_width_data = zeros(1, data_filtered_length, 'like', full_width_sample);
        
        for index = 1:data_filtered_length
            full_width_data(index) = sum(data_fi(index:index+num_taps-1).*coefficients_fi);
        end
        
        filtered_data_fpga = fi(full_width_data, true, output_data_width, n+n);
        
        % Dump out fixed point input and output samples as a VHDL package
        create_package(coefficients_fi, 'CoefficientsFi', '../rtl/pkg/');
        create_package(data_fi, 'InputSamplesFi', '../rtl/pkg/');
        create_package(filtered_data_fpga, 'OutputSamplesFi', '../rtl/pkg/');
end
