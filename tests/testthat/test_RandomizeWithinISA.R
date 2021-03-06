##### COPYRIGHT #############################################################################################################
#
# Copyright (C) 2018 JANSSEN RESEARCH & DEVELOPMENT, LLC
# This package is governed by the JRD OCTOPUS License, which is the
# GNU General Public License V3 with additional terms. The precise license terms are located in the files
# LICENSE and GPL.
#
#############################################################################################################################.


context("Test RandomizeWithinISA.R")
source("TestHelperFunctions.R")

###### RandomizeWithinISA.POCRandomizer######################################################################################
#
# Test  - ISA 1 Randomizer -  Should be a POCRandomizer
#   When the call InitializeTrialRandomizer occurs the ISA randomizes are setup.
#   The test could be run after the call to InitializeTrialRandomizer
#   however, calling Randomize actually tests the the InitializeISARandomizer.XXX and Randomize.XXX
#   both did the correct thing.
#
#############################################################################################################################.
#
strPrefixTest <- "ISA 2 Randomizer - POCRandomizer"
test_that(strPrefixTest,
{

    gnPrintDetail <<- 0

    #Set everything
    vISAStartTime <- c(0, 0)
    cTrialDesign  <- SetupTrialDesign2ISA( )
    cTrialRand    <- InitializeTrialRandomizer( cTrialDesign, vISAStartTime )
    strPrefixTest <- "ISA 1 Randomizer RandomizeWithinISA.POCRandomizer "

    strExp <- "POCRandomizer"
    strRet <- class( cTrialDesign$cISADesigns[[ "cISA1" ]]  )
    expect_equal( strRet, strExp )

    #Check the ISARand in cTrialRand
    strRet <- class( cTrialRand[[1]] )

    #Set the status of ISA2 to 0 so it is not open yet and should not have patients randomized to it
    vISAStatus <- c( 1, 0 )

    bPassTest <- TRUE
    vQtyISA   <- c( 0, 0 )  #Keep count of the number of patients assigned to each ISA, this example should have ISA2 = 0

    #ISA 1 utilizes a POCRandomzier so the initial patients should all be on two of the treatments
    vQtyPatsInit <- cTrialDesign$cISADesigns[[1]]$vQtyPatsInit
    vQtyPats     <- cTrialDesign$cISADesigns[[1]]$vQtyPats

    nQtyTrt      <- length( vQtyPatsInit )
    vTrt         <- 1:nQtyTrt
    nQtyPatsInit <- sum( vQtyPatsInit )
    nQtyPats     <- sum( vQtyPats )
    nQtyPats2    <- nQtyPats - nQtyPatsInit
    vProbTrtPt2  <- (vQtyPats - vQtyPatsInit)/nQtyPats2  # This is used in the last test to make sure we are getting about the right number of patients


    bISATest      <- TRUE     # Used to make sure patients are only assigned to ISA2
    bInitPatTest  <- TRUE     # Test to make sure the patients are only assigned to the open treatments in the POC part
    bInitPatTest2 <- TRUE     # Used to track if the patients are close to equally randomized in the POC
    bPatTest2     <- TRUE
    vTrtCount     <- rep( 0, nQtyTrt )
    vQtyISA       <- c( 0, 0 )  #Keep count of the number of patients assigned to each ISA, this example should have ISA2 = 0


    bExp <- TRUE
    #The initial patient randomization will be done 10 times just to make sure it is not an accident that no patients are assigned to the
    #incorrect treatments

    # Randomize the patients for 10 trials and make sure no tests fail.
    nQtyTest <- 20
    for( iTest in 1:nQtyTest )
    {

        cTrialRand   <- InitializeTrialRandomizer( cTrialDesign, vISAStartTime )

        vTrtCount    <- rep( 0, nQtyTrt )
        for( i in 1:nQtyPatsInit )
        {
            lRandRet   <- Randomize( cTrialRand, vISAStatus, 0.0  )
            cTrialRand <- lRandRet$cRandomizer

            vQtyISA[ lRandRet$nISA ]   <- vQtyISA[ lRandRet$nISA ] + 1
            vTrtCount[ lRandRet$nTrt ] <- vTrtCount[ lRandRet$nTrt ] + 1

        }

        # Test to make sure no patients were assigned to ISA2
        nExp     <- 0
        nRet     <- vQtyISA[ 2 ]
        expect_equal( nRet, nExp  )
        #AddTest( cTestRandomizer, paste( strPrefixTest, " Number of patients assigned to ISA2 when it is closed was incorrect. "), nExp, nRet )

        # Test to make sure the number of patients assigned to the treatments not open during the POC = 0
        bInitPatTest  <- ( sum( vTrtCount[ vQtyPatsInit== 0 ] ) == 0 )
        expect_true( bInitPatTest )

        # Test to make sure each of the open arms is near equal in terms of the number of patients
        nCutoff       <- qbinom( 0.99, nQtyPatsInit,0.5)
        bInitPatTest2 <- all( vTrtCount < nCutoff )
        expect_true( bInitPatTest2 )

        vQtyISA2     <- rep( 0, nQtyTrt )
        vTrtCount    <- rep( 0, nQtyTrt )
        # Randomize after the POC and keep track of the number of patients randomized to each treatment
        nRand        <- floor( nQtyPats2 - nQtyPats2/2 )
        for( i in 1:nRand )
        {
            lRandRet   <- Randomize( cTrialRand, vISAStatus, 0.0  )
            cTrialRand <- lRandRet$cRandomizer
            vTrtCount[ lRandRet$nTrt ]  <- vTrtCount[ lRandRet$nTrt ] + 1
            vQtyISA2[ lRandRet$nISA ]   <- vQtyISA2[ lRandRet$nISA ] + 1

        }

        # Test to make sure no patients were assigned to ISA2  Number of patients assigned to ISA2 during non POC portion, when it is closed, was incorrect. "
        nRet     <- vQtyISA[ 2 ]
        expect_equal( nRet, 0 )

        # If the value from a chisq.test is small there is a possibility of a bug
        #  Note: this test is run ", nQtyTest, " times, if only 1-2 errors are reported it may not be a problem as this could happen by chance.")

        dPVal     <- chisq.test( vTrtCount, p=vProbTrtPt2 )$p.value

        bRet      <- dPVal >= 0.05
        expect_true( bRet )

        nRand        <- nQtyPats2 - nRand
        for( i in 1:nRand )
        {
            lRandRet   <- Randomize( cTrialRand, vISAStatus, 0.0  )
            cTrialRand <- lRandRet$cRandomizer
            vTrtCount[ lRandRet$nTrt ]  <- vTrtCount[ lRandRet$nTrt ] + 1

        }
        vExp   <- vQtyPats - vQtyPatsInit
        # At the end of the trial in the non-POC the number of patients assigned to the treatments was incorrect."

        expect_equal( vTrtCount, vExp )



    }

})


###### Test ISA 2 Randomzier #############################################################################################
#
# Test  - ISA 2 Randomizer - Should be an EqualRandomizer
# This test tests InitializeTrialRandomizer and subsequent calls to Randomizer
##########################################################################################################################.

strPrefixTest  <- "ISA 2 Randomizer - Equal Randomizer"
test_that(strPrefixTest,
{
    #Reset everything

    gnPrintDetail <<- 0
    vISAStartTime <- c(0, 0)
    cTrialDesign  <- SetupTrialDesign2ISA( )
    cTrialRand    <- InitializeTrialRandomizer( cTrialDesign, vISAStartTime  )
    nISA          <- 2



    strExp <- "EqualRandomizer"
    strRet <- class( cTrialDesign$cISADesigns[[ "cISA2" ]]  )

    expect_equal( strRet, strExp )

    #Check the ISARand in cTrialRand
    strRet <- class( cTrialRand[[ nISA ]])
    expect_equal( strRet, strExp )


    #Set the status of ISA1 to 0 so it is not open yet and should not have patients randomized to it
    vISAStatus <- c( 0, 1 )

    bPassTest <- TRUE
    vQtyISA   <- c( 0, 0 )  #Keep count of the number of patients assigned to each ISA, this example should have ISA2 = 0

    #ISA 1 utilizes a POCRandomzier so the initial patients should all be on two of the treatments

    vQtyPats     <- cTrialDesign$cISADesigns[[ nISA ]]$vQtyPats

    nQtyTrt      <- length( vQtyPats )
    vTrt         <- 1:nQtyTrt
    nQtyPats     <- sum( vQtyPats )
    nQtyPats2    <- floor( nQtyPats/2 )   #Will split the patients in half to make sure each have is randomized in about the right proportions
    vProbTrtPt   <- (vQtyPats)/nQtyPats  # This is used in the last test to make sure we are getting about the right number of patients


    bISATest      <- TRUE     # Used to make sure patients are only assigned to ISA2
    bInitPatTest  <- TRUE     # Test to make sure the patients are only assigned to the open treatments in the POC part
    bInitPatTest2 <- TRUE     # Used to track if the patients are close to equally randomized in the POC
    bPatTest2     <- TRUE
    vTrtCount     <- rep( 0, length( cTrialDesign$vTrtLab ) )
    vQtyISA       <- c( 0, 0 )  #Keep count of the number of patients assigned to each ISA, this example should have ISA2 = 0


    bExp <- TRUE
    #The initial patient randomization will be done 10 times just to make sure it is not an accident that no patients are assigned to the
    #incorrect treatments

    # Randomize the patients for 10 trials and make sure no tests fail.
    nQtyTest <- 20
    for( iTest in 1:nQtyTest )
    {

        cTrialRand   <- InitializeTrialRandomizer( cTrialDesign, vISAStartTime )

        vTrtCount    <- rep( 0, length( cTrialDesign$vTrtLab ) )
        for( i in 1:nQtyPats2 )
        {
            lRandRet   <- Randomize( cTrialRand, vISAStatus, 0.0  )
            cTrialRand <- lRandRet$cRandomizer

            vQtyISA[ lRandRet$nISA ]    <- vQtyISA[ lRandRet$nISA ] + 1
            vIndex                      <- cTrialDesign$vTrtLab== lRandRet$nTrt &  cTrialDesign$vISALab == nISA
            vTrtCount[  vIndex ]        <- vTrtCount[  vIndex ] + 1


        }
        vTrtCount <- vTrtCount[  cTrialDesign$vISALab == nISA ]

        # Test to make sure no patients were assigned to ISA1
        nExp     <- 0
        nRet     <- vQtyISA[ 1 ]
        expect_equal( nRet, nExp )

        dPVal     <- chisq.test( vTrtCount, p=vProbTrtPt )$p.value


        strErr <- paste(" EqualRandomizer - Randomize first half of patients test  for expected number of patients assigned to each treatment")
        strErr <- paste( strErr, paste( vTrtCount, collapse = ", ") )
        strErr <- paste( strErr, " Note: this test is run ", nQtyTest, " times, if only 1-2 errors are reported it may not be a problem as this could happen by chance.")

        bRet      <- dPVal >= 0.01
        #if( !bRet )
        #    print(paste( "pval 1 ", dPVal))
        expect_true( bRet,  strErr)

        vTrtCount2    <- rep( 0, length( cTrialDesign$vTrtLab ) )
        for( i in (nQtyPats2+1):nQtyPats )
        {
            lRandRet   <- Randomize( cTrialRand, vISAStatus, 0 )
            cTrialRand <- lRandRet$cRandomizer

            vQtyISA[ lRandRet$nISA ]    <- vQtyISA[ lRandRet$nISA ] + 1
            vIndex                      <- cTrialDesign$vTrtLab== lRandRet$nTrt &  cTrialDesign$vISALab == nISA
            vTrtCount2[ vIndex ] <- vTrtCount2[ vIndex ] + 1

        }

        # Test to make sure no patients were assigned to ISA1
        nExp     <- 0
        nRet     <- vQtyISA[ 1 ]
        expect_equal( nRet, nExp )
        vTrtCount2 <- vTrtCount2[  cTrialDesign$vISALab == nISA ]

        dPVal     <- chisq.test( vTrtCount2, p=vProbTrtPt )$p.value

        #EqualRandomizer - Randomize second half of patients test  for expected number of patients assigned to each treatment", paste( vTrtCount, collapse = ", "),
        # Note: this test is run ", nQtyTest, " times, if only 1-2 errors are reported it may not be a problem as this could happen by chance.")


        bRet      <- dPVal >= 0.01

        if( !bRet )
            print(paste( "pval 2 ", dPVal))
        expect_true( bRet )

        vTrtCount <- vTrtCount + vTrtCount2
        vExp      <- vQtyPats
        expect_equal( vTrtCount, vExp )


    }

})





###### Test ISA 2 Randomzier - DelayedStartRandomizer ###################################################################
#
# Test  - ISA 2 Randomizer - "DelayedStartRandomizer"
#
##########################################################################################################################.

strPrefixTest <- "ISA 2 Randomizer - DelayedStartRandomizer"
test_that(strPrefixTest,
{
    #Reset everything

    gnPrintDetail <<- 0
    vISAStartTime <- c( 0, 6 )
    cTrialDesign  <- SetupTrialDesign2ISA(strISA2Randomizer = "DelayedStartRandomizer" )
    cTrialRand    <- InitializeTrialRandomizer( cTrialDesign, vISAStartTime  )
    nISA          <- 2


    strExp <- "DelayedStartRandomizer"
    strRet <- class( cTrialDesign$cISADesigns[[ "cISA2" ]]  )

    expect_equal( strRet, strExp )

    #Check the ISARand in cTrialRand
    strRet <- class( cTrialRand[[ nISA ]])
    expect_equal( strRet, strExp )


    #Set the status of ISA1 to 0 so it is not open yet and should not have patients randomized to it
    vISAStatus <- c( 0, 1 )

    bPassTest <- TRUE
    vQtyISA   <- c( 0, 0 )  #Keep count of the number of patients assigned to each ISA, this example should have ISA2 = 0

    #ISA 1 utilizes a POCRandomzier so the initial patients should all be on two of the treatments

    vQtyPats     <- cTrialDesign$cISADesigns[[ nISA ]]$vQtyPats

    nQtyTrt      <- length( vQtyPats )
    vTrt         <- 1:nQtyTrt
    nQtyPats     <- sum( vQtyPats )

    #Splitting the patients into two parts, the first part should only receive dose 1,2,3 because 4 is not open.
    nQtyPats2    <- floor( nQtyPats/2 )


    strDelayedTrt <- cTrialDesign$cISADesigns[[2]]$vTrtLab[ 4 ]

    bISATest      <- TRUE     # Used to make sure patients are only assigned to ISA2
    bInitPatTest  <- TRUE     # Test to make sure the patients are only assigned to the open treatments in the POC part
    bInitPatTest2 <- TRUE     # Used to track if the patients are close to equally randomized in the POC
    bPatTest2     <- TRUE
    vTrtCount     <- rep( 0, length( cTrialDesign$vTrtLab ) )

    vQtyISA       <- c( 0, 0 )  #Keep count of the number of patients assigned to each ISA, this example should have ISA2 = 0


    bExp <- TRUE
    #The initial patient randomization will be done 10 times just to make sure it is not an accident that no patients are assigned to the
    #incorrect treatments

    # Randomize the patients for nQtyTest  trials and make sure no tests fail.
    nQtyTest <- 20
    for( iTest in 1:nQtyTest )
    {

        cTrialRand   <- InitializeTrialRandomizer( cTrialDesign, vISAStartTime)

        vTrtCount    <- rep( 0, length( cTrialDesign$vTrtLab ) )
        for( i in 1:nQtyPats2 )
        {
            #Testing a value greater than start time of ISA2 delayed doses.
            lRandRet   <- Randomize( cTrialRand, vISAStatus,  7.0  )
            cTrialRand <- lRandRet$cRandomizer
            lRandRet$nTrt
            lRandRet$cRandomizer[[2]][[1]]
            length(lRandRet$cRandomizer[[2]][[1]])
            length( cTrialRand[[2]][[1]])

            vQtyISA[ lRandRet$nISA ]    <- vQtyISA[ lRandRet$nISA ] + 1
            vIndex                      <- cTrialDesign$vTrtLab== lRandRet$nTrt &  cTrialDesign$vISALab == nISA
            vTrtCount[  vIndex ]        <- vTrtCount[  vIndex ] + 1


        }
        vTrtCount <- vTrtCount[  cTrialDesign$vISALab == nISA ]
        nQtyOfPatientsOnDelayedTrt <- vTrtCount[ cTrialDesign$cISADesigns[[2]]$vTrtLab == strDelayedTrt ]

        expect_equal( nQtyOfPatientsOnDelayedTrt, 0, label= "Delayed treatment patient count greater than 0.")

        #Since one treatment is delayes
        # Test to make sure no patients were assigned to ISA1
        nExp     <- 0
        nRet     <- vQtyISA[ 1 ]
        expect_equal( nRet, nExp )


        # Need to drop the count on the teatment that is no open before testing.

        dPVal     <- chisq.test( vTrtCount[ -4 ], p=rep( 1/3,3) )$p.value


        strErr <- paste(" EqualRandomizer - Randomize first half of patients test  for expected number of patients assigned to each treatment")
        strErr <- paste( strErr, paste( vTrtCount, collapse = ", ") )
        strErr <- paste( strErr, " Note: this test is run ", nQtyTest, " times, if only 1-2 errors are reported it may not be a problem as this could happen by chance.")

        bRet      <- dPVal >= 0.01
        #if( !bRet )
        #    print(paste( "pval 1 ", dPVal))
        expect_true( bRet,  strErr)

        vTrtCount2    <- rep( 0, length( cTrialDesign$vTrtLab ) )
        for( i in (nQtyPats2+1):nQtyPats )
        {
            lRandRet   <- Randomize( cTrialRand, vISAStatus, 14.0 )
            cTrialRand <- lRandRet$cRandomizer

            vQtyISA[ lRandRet$nISA ]    <- vQtyISA[ lRandRet$nISA ] + 1
            vIndex                      <- cTrialDesign$vTrtLab== lRandRet$nTrt &  cTrialDesign$vISALab == nISA
            vTrtCount2[ vIndex ] <- vTrtCount2[ vIndex ] + 1

        }

        # Test to make sure no patients were assigned to ISA1
        nExp     <- 0
        nRet     <- vQtyISA[ 1 ]
        expect_equal( nRet, nExp )

        vTrtCount2 <- vTrtCount2[  cTrialDesign$vISALab == nISA ]

        # dPVal      <- chisq.test( vTrtCount2, p=rep( 0.25, 4 ) )$p.value
        #
        # #EqualRandomizer - Randomize second half of patients test  for expected number of patients assigned to each treatment", paste( vTrtCount, collapse = ", "),
        # # Note: this test is run ", nQtyTest, " times, if only 1-2 errors are reported it may not be a problem as this could happen by chance.")
        #
        #
        # bRet      <- dPVal >= 0.05
        #
        # if( !bRet )
        #     print(paste( "pval 2 ", dPVal))
        # expect_true( bRet )

        vTrtCount <- vTrtCount + vTrtCount2
        vExp      <- vQtyPats
        expect_equal( vTrtCount, vExp )


    }

})
