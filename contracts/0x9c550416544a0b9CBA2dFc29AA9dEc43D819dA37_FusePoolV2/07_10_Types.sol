// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Types {
    struct FeeRecipients {
        address operations;
        address validatorAcquisition;
        address PCR;
        address yield;
        address xChainValidatorAcquisition;
        address indexFundPools;
        address gAMPRewardsPool;
        address OTCSwap;
        address rescueFund;
        address protocolImprovement;
        address developers;
    }

    struct Fees {
        uint16 operations;
        uint16 validatorAcquisition;
        uint16 PCR;
        uint16 yield;
        uint16 xChainValidatorAcquisition;
        uint16 indexFundPools;
        uint16 gAMPRewardsPool;
        uint16 OTCSwap;
        uint16 rescueFund;
        uint16 protocolImprovement;
        uint16 developers;
    }

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 started;
        uint256 unlocks;
    }

    enum FuseProduct {
        None,
        OneYear,
        ThreeYears,
        FiveYears
    }

    struct Amplifier {
        FuseProduct fuseProduct;
        address minter;
        uint256 created;
        uint256 expires;
        uint256 numClaims;
        uint256 lastClaimed;
        uint256 fused;
        uint256 unlocks;
        uint256 lastFuseClaimed;
    }

    struct AmplifierV2 {
        FuseProduct fuseProduct;
        address minter;
        uint16 numClaims;
        uint48 lastClaimed;
        uint48 created;
        uint48 expires;
        uint48 fused;
        uint48 unlocks;
    }

    struct AmplifierFeeRecipients {
        address operations;
        address validatorAcquisition;
        address developers;
    }

    struct Transistor {
        address minter;
        uint256 created;
        uint256 expires;
        uint256 numClaims;
        uint256 lastClaimed;
    }

    struct TransistorFeeRecipients {
        address creationFee;
        address creationTax;
        address renewalFee;
        address reverseFee;
        address claimFeeOperations;
        address claimFeeDevelopers;
    }

    struct Checkpoint {
        uint32 fromBlock;
        uint224 shares;
    }

    struct Pot {
        uint48 timestamp;
        uint208 value;
    }
}