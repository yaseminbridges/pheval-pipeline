#!/usr/bin/env nextflow

include { prepareGADOConfigurations } from './modules/tools/gado/gadoPrepareConfigurations.nf'


workflow {
    gado_configurations_ch = prepareGADOConfigurations(Channel.fromList(params.gado_configs))
    }