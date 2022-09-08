//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../external/IERC677Receiver.sol";

/// @title StakingIncentives allow users to stake a token to receive a reward.
interface IStakingIncentives is IERC677Receiver {
    // Used in IERC677 deposits
    struct StakingDeposit {
        // The account that is depositing the staking token
        address account;
    }
}