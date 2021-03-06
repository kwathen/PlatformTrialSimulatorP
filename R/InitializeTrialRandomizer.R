##### COPYRIGHT #############################################################################################################
#
# Copyright (C) 2018 JANSSEN RESEARCH & DEVELOPMENT, LLC
# This package is governed by the JRD OCTOPUS License, which is the
# GNU General Public License V3 with additional terms. The precise license terms are located in the files
# LICENSE and GPL.
#
#############################################################################################################################.


#' @name InitializeTrialRandomizer.default
#' @title InitializeTrialRandomizer.default
#' @description {This function is used to initialize the trial randomizer. The default version each
#' ISA and calls the InitializeISARandomizer.  Since each ISA can have a specific randomizer  the default
#' for the TrialRandomizer is just to initialize each ISA randomizer.}
#' @param cTrialDesign Trial design opbject giving specifics about the trial design.
#' @param vISAStartTime A vector of times that each ISA opens/starts in the trial.  A vector of c(0,...) would indicate all ISAs start at the start of the trial.
#' @seealso { \href{https://github.com/kwathen/OCTOPUS/blob/master/R/InitializeTrialRandomizer.R}{View Code on GitHub} }
#' @export
InitializeTrialRandomizer  <- function( cTrialDesign, vISAStartTimes )
{
    UseMethod( "InitializeTrialRandomizer", cTrialDesign )
}

#' @seealso { \href{https://github.com/kwathen/OCTOPUS/blob/master/R/InitializeTrialRandomizer.R}{View Code on GitHub} }
#' @export
InitializeTrialRandomizer.default  <- function( cTrialDesign, vISAStartTimes )
{
    nQtyISA   <- cTrialDesign$nQtyISAs

    lISARands <- list()
    for( iISA in 1:nQtyISA )
    {
        strISAName <- paste( "cISA", iISA, sep="" )

        lISARands[[ paste( "lISA", iISA, sep="")]] <- InitializeISARandomizer( cTrialDesign$cISADesigns[[ strISAName ]], vISAStartTimes[ iISA ]  )

    }
    cISARand <- structure( lISARands, class= class( cTrialDesign) )

    return( cISARand )

}
