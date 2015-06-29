% this script executes the model with a single uniform desired value
% for the purpose of measuring the effect of a disturbance with a specific 
% signal upon the output of the controller-plant model
try
    % add all the paths containing the model and the functions we use
    addpath(CT_ModelPath);
    addpath(strcat(CT_ScriptsPath, '/ObjectiveFunctions'));
    addpath(strcat(CT_ScriptsPath, '/Util'));
    % configure the static model configuration parameters and load the
    % model into the system memory
    load_system(CT_ModelFile);
    CT_CheckCorrectOutput(CT_ActualVariableName);
    run(CT_ModelConfigurationFile);
    
    % double the model simulation time since this is the maximum possible
    % total simulation time configurable in the GUI and parallelization
    % requires a preset simulation time
    simulationTime = CT_ModelSimulationTime * 2;
    CT_SetSimulationTime(simulationTime);
    % retrieve the model simulation step, as it might have been changed by
    % the configuration script
    CT_ModelTimeStep = CT_GetSimulationTimeStep();
    CT_SimulationSteps=simulationTime/CT_ModelTimeStep;
               
    % pre-allocate space
	ObjectiveFunctionValues = zeros(7,1);

    % start the timer to measure the running time of the model together
    % with the objective function computation
    tic;
    % generate the time for the desired value  
    assignin('base', CT_DesiredVariableName, CT_GenerateSineSignal(CT_SimulationSteps, CT_ModelTimeStep, CT_DesiredValue, CT_SineAmplitude, CT_SineFrequency));
    assignin('base', CT_DisturbanceVariableName, CT_GenerateConstantSignal(1, CT_SimulationSteps*CT_ModelTimeStep, 0));

    % build model if needed
    accelbuild(gcs);
    
    % run the simulation in accelerated mode
    if (CT_AccelerationDisabled)
        simOut = sim(CT_ModelFile, 'SaveOutput','on');
    else
        simOut = sim(CT_ModelFile, 'SimulationMode', 'accelerator', 'SaveOutput','on');
    end

    actualValue = simOut.get(CT_ActualVariableName);
            
    % get the starting index for stability, precision and steadiness
    indexStableStart = CT_GetIndexForTimeStep(actualValue.time, CT_ModelSimulationTime + CT_TimeStable);
    
    % calculate the objective functions
    ObjectiveFunctionValues(1) = ObjectiveFunction_Stability(actualValue, indexStableStart);
    ObjectiveFunctionValues(2) = ObjectiveFunction_Precision(actualValue, CT_DesiredValue, indexStableStart);
    ObjectiveFunctionValues(3) = ObjectiveFunction_Smoothness(actualValue, CT_DesiredValue, 1, CT_SmoothnessStartDifference);
    ObjectiveFunctionValues(4) = ObjectiveFunction_Responsiveness(actualValue, CT_DesiredValue, 1, CT_ResponsivenessClose);
    [ObjectiveFunctionValues(5), ObjectiveFunctionValues(6)] = ObjectiveFunction_Steadiness(actualValue, indexStableStart);
    ObjectiveFunctionValues(7) = ObjectiveFunction_PhysicalRange(actualValue, CT_ActualValueRangeStart, CT_ActualValueRangeEnd);

    % stop the timer
    duration = toc;
    % output the model running time (?)
    display('Successful execution of the model');
    display(strcat('runningTime=', num2str(duration)));
    % plot the result
    str = {'Objective function values:'};
    str = [str, strcat('Stability: ', num2str(ObjectiveFunctionValues(1)))];
    str = [str, strcat('Precision: ', num2str(ObjectiveFunctionValues(2)))];
    str = [str, strcat('Smoothness: ', num2str(ObjectiveFunctionValues(3)))];
    str = [str, strcat('Responsiveness: ', num2str(ObjectiveFunctionValues(4)))];
    str = [str, strcat('Steadiness: ', num2str(ObjectiveFunctionValues(5)))];
    str = [str, strcat('Physical range exceeded: ', num2str(ObjectiveFunctionValues(7)))];
    str = [str, ''];
        
    % plot the result
    eval(strcat('InterpolatedDesiredValues = interp1(',CT_DesiredVariableName,'.time,',CT_DesiredVariableName,'.signals.values, actualValue.time);'));
    plot(actualValue.time, InterpolatedDesiredValues,actualValue.time, actualValue.signals.values);

    annotation('textbox', [0, 0.5, 0, 0], 'string', str);
    
    legend('Desired Value','Actual Value','Disturbance Value');
catch e
    display('Error during model execution');
    display(getReport(e));
end