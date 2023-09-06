function pulse_train = create_pulsetrain(pulse_volts, pulse_duration, interpulse_interval, total_duration, samples)
    numreps = total_duration/(pulse_duration + interpulse_interval);
    pulse_duration_samples = pulse_duration * samples;
    interpulse_interval_samples = interpulse_interval * samples;

    pulse_volts_samples = pulse_volts*ones(1,int32(pulse_duration_samples));
    interpulse_volts_samples = zeros(1,int32(interpulse_interval_samples));

    pulse_train = repmat([pulse_volts_samples,interpulse_volts_samples],1,numreps);

    if size(pulse_train,2)>(total_duration*samples)
        pulse_train((total_duration*samples)+1:end)=[];
    end
end