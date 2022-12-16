// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
library Structs{
    struct StakingParams{
        address stakingToken;
        uint256 minStakeAmount;
        uint256 unboundPeriodBlock;
        uint256 instantUnboundFeePercentage;
        address accessControl;
        address feeAddress;
        uint256 commissionPercentage;
        uint256 payoutIntervalBlock;
        bool    allowedInstantUnbound;
    }

}