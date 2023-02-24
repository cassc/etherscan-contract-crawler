// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../ConvexTokenStakerMainnet.sol";

/// @title ConvexLUSDv3CRVStaker
/// @author Angle Labs, Inc.
/// @dev Implementation of `ConvexTokenStakerMainnet` for the LUSD-3CRV pool
contract ConvexLUSDv3CRVStaker is ConvexTokenStakerMainnet {
    // ============================= VIRTUAL FUNCTIONS =============================

    /// @inheritdoc BorrowStaker
    function asset() public pure override returns (IERC20) {
        return IERC20(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);
    }

    /// @inheritdoc ConvexTokenStakerMainnet
    function baseRewardPool() public pure override returns (IConvexBaseRewardPool) {
        return IConvexBaseRewardPool(0x2ad92A7aE036a038ff02B96c88de868ddf3f8190);
    }

    /// @inheritdoc ConvexTokenStaker
    function poolPid() public pure override returns (uint256) {
        return 33;
    }
}