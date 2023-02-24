// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../ConvexTokenStakerMainnet.sol";

/// @title Convex3CRVStaker
/// @author Angle Labs, Inc.
/// @dev Implementation of `ConvexTokenStakerMainnet` for the 3CRV pool
contract Convex3CRVStaker is ConvexTokenStakerMainnet {
    // ============================= VIRTUAL FUNCTIONS =============================

    /// @inheritdoc BorrowStaker
    function asset() public pure override returns (IERC20) {
        return IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    }

    /// @inheritdoc ConvexTokenStakerMainnet
    function baseRewardPool() public pure override returns (IConvexBaseRewardPool) {
        return IConvexBaseRewardPool(0x689440f2Ff927E1f24c72F1087E1FAF471eCe1c8);
    }

    /// @inheritdoc ConvexTokenStaker
    function poolPid() public pure override returns (uint256) {
        return 9;
    }
}