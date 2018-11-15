import os
import sys
import shutil
import subprocess




###############################################################################
# CONFIGURATION
###############################################################################
extensions = ['.vhd', '.vhdl']
src_folders = ['rtl', 'sim']

packages = [
             'pkg_ComponentDeclaration.vhd',
             'pkg_Common.vhd',
             'pkg_CoefficientsFi.vhd',
             'pkg_InputSamplesFi.vhd',
             'pkg_OutputSamplesFi.vhd',
           ]

include_files = [ # If empty, all will be included
                  'AddersTree.vhd',
                  'FIR.vhd',
                  'ParallelFIR.vhd',
                  'ParallelFIR_tb.vhd',
                ]

exclude_files = []

testbenches = [
                'ParallelFIR_tb',
              ]





###############################################################################
# CONSTANTS
###############################################################################

sim_time = sys.argv[1]

sim_dir = os.path.dirname( os.path.abspath(__file__) )

waves_dir = os.path.abspath(sim_dir  + '/waves/')

root_dir = os.path.abspath(sim_dir  + '../../')

packages_folder = os.path.abspath(root_dir + '/rtl/pkg/')

workdir = 'work'


analyze_command_begin = 'ghdl -a --workdir=work --ieee=synopsys -fexplicit \"'
analyze_command_end = '\"'


elaborate_command = 'ghdl -e --workdir=work --ieee=synopsys -fexplicit '

run_command = 'ghdl -r --workdir=work --ieee=synopsys -fexplicit '




###############################################################################
# SCRIPT
###############################################################################
# work dir cleanup
if os.path.exists(os.path.join(sim_dir, workdir)):
    shutil.rmtree(os.path.join(sim_dir, workdir))
os.mkdir(workdir)



# Analyze packages
print('\n* ANALYZE PACKAGES')
for package in packages:
    package_file = os.path.join(packages_folder, package)
    complete_command = analyze_command_begin + package_file + analyze_command_end
    subprocess.call(complete_command)

print('\nAnalyze packages done.\n\n\n')




# Analyze all the .vhd files in the configured dirs
print('\n* ANALYZE ALL .vhd SOURCES')
for src_folder in src_folders:
  scan_folder = os.path.join(root_dir, src_folder)
  # print('Scanning folder ' + scan_folder)

  for root, dirs, files in os.walk(scan_folder):
      for file in files:
          for extension in extensions:
              if file.endswith(extension) and (file not in exclude_files) and (file not in packages):
                  if not(include_files) or (file in include_files):
                      file_path = os.path.join(root, file)
                      complete_command = analyze_command_begin + file_path + analyze_command_end
                      subprocess.call(complete_command)

print('\nAnalyze all .vhd sources done.\n\n\n')



# Elaborate the testbench
print('\n* ELABORATE THE TESTBENCHES')
elaborate_error = 0

for testbench in testbenches:
    elaborate_error = subprocess.call(elaborate_command + testbench)

if elaborate_error:
    print('\nELABORATE THE TESTBENCHES FAILED!')
else:
    print('\nElaborate the testbenches done.')




# Run the testbenches
print('\n* RUN THE TESTBENCHES')
run_error = 0

for testbench in testbenches:
    run_error = subprocess.call(run_command + testbench + ' --wave=' + testbench + '.ghw --stop-time=' + sim_time)

if run_error:
    print('\nRUN THE TESTBENCHES FAILED!')
else:
    print('\nRun the testbenches done.')




# Open wave files
if not run_error:
    print('\n* OPEN THE WAVE FILES')
    found_wave_file = 0

    for testbench in testbenches:
        testbenche_waves_dir = os.path.abspath(waves_dir + '/' + testbench)
        print(testbenche_waves_dir)

        for root, dirs, files in os.walk(testbenche_waves_dir):
          for file in files:
              if file.endswith('.gtkw'):
                  found_wave_file = 1
                  subprocess.Popen( ['gtkwave', testbench + '.ghw', '-a', os.path.join(root, file)] )

    if not found_wave_file:
        subprocess.Popen( ['gtkwave', testbench + '.ghw'] )

else:
    print('\n* NOT OPENING THE WAVE FILES DUE TO PREVIOUS RUN ERRORS!')
