function runSimulationVHDL

    command = 'python ../sim/run_ghdl_sim.py 6us';
	simulation_success = 0;
    
    cd '../sim/'
    
    
	while simulation_success == 0
        [status,cmdout] = system(command,'-echo')
        if status==0
            if strfind(cmdout, 'RUN ERROR')
                fprintf('\nGHDL start error, retrying.\n')
            else
                simulation_success = 1
                fprintf('\nVHDL simulation completed successfully.\n')
            end
        else
            fprintf('Sim run error.')
        end
    end
    
    cd '../scripts/'
end