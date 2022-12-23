// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../../StakeDAOTokenStaker.sol";

/// @title StakeDAOFRAXBPStaker
/// @author Angle Labs, Inc.
/// @dev Implementation of `StakeDAOTokenStaker` for the FRAXBP pool
contract StakeDAOFRAXBPStaker is StakeDAOTokenStaker {
    // ============================= VIRTUAL FUNCTIONS =============================
    /// @inheritdoc BorrowStaker
    function asset() public pure override returns (IERC20) {
        return IERC20(0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC);
    }

    /// @inheritdoc StakeDAOTokenStaker
    function _vault() internal pure override returns (IStakeCurveVault) {
        return IStakeCurveVault(0x11D87d278432Bb2CA6ce175e4a8B4AbDaDE80Fd0);
    }

    /// @inheritdoc StakeDAOTokenStaker
    function _gauge() internal pure override returns (ILiquidityGauge) {
        return ILiquidityGauge(0xBe77585F4159e674767Acf91284160E8C09b96D8);
    }
}