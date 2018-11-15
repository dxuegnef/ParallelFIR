function create_package(data, name, output_dir)

        n_samples = length(data);
        n_bits = data.WordLength(1);

        file_path = strcat( output_dir, 'pkg_', name, '.vhd');
        file = fopen(file_path, 'w');

        % Write header
        fprintf(file, '\n' );
        fprintf(file, ['library ieee;\n'] );
        fprintf(file, ['use     ieee.std_logic_1164.all;\n'] );

        fprintf(file, '\n\n' );
        fprintf(file, ['package pkg_' name ' is\n'] );
        fprintf(file, '\n' );

        % Type declaration
        fprintf(file, ['  type T_' upper(name) ' is array (0 to ' num2str(n_samples) ...
                       '-1) of std_logic_vector(' num2str(n_bits) '-1 downto 0);\n'] );
        fprintf(file, '\n' );

        % Array constant
        fprintf(file, ['  constant PKG_' upper(name) ' : T_' upper(name) ' := (\n']);
        for i = 1 : length(data)-1
            fprintf(file, ['    "' bin(data(i)) '",\n']);
        end
        fprintf(file, ['    "' bin(data(length(data))) '"\n  );\n\n']);

        % Concatenated vector
        fprintf(file, ['  constant PKG_' upper(name) '_CONCAT : std_logic_vector(' num2str(n_samples*n_bits-1) ' downto 0) := (\n']);
        for i = 1 : length(data)-1
            fprintf(file, ['    "' bin(data(i)) '" & \n']);
        end
        fprintf(file, ['    "' bin(data(length(data))) '"\n  );\n\n']);

        fprintf(file, ['end pkg_' name ';\n'] );
        fclose(file);

end
