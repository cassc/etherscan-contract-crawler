// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library StakingUtils {
    struct StakingConfiguration {
        uint256 rewardRate;
        uint256 startTime;
        uint256 minStake;
        uint256 maxStake;
        ERC20 stakingToken;
        ERC20 rewardsToken;
    }

    struct TaxConfiguration {
        uint256 stakeTax;
        uint256 unStakeTax;
        uint256 hpayFee;
        address feeAddress;
        address hpayFeeAddress;
        ERC20 hpayToken;
    }

    struct AutoCompundConfiguration {
        uint256 performaceFee;
        uint256 compundReward;
    }
}