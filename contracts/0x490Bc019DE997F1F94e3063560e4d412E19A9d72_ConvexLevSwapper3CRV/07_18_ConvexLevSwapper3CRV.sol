// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../CurveLevSwapper3CRV.sol";

/// @title ConvexLevSwapper3CRV
/// @author Angle Labs, Inc.
/// @notice Implements CurveLevSwapper3CRV with a Convex staker
contract ConvexLevSwapper3CRV is CurveLevSwapper3CRV {
    constructor(
        ICoreBorrow _core,
        IUniswapV3Router _uniV3Router,
        address _oneInch,
        IAngleRouterSidechain _angleRouter
    ) CurveLevSwapper3CRV(_core, _uniV3Router, _oneInch, _angleRouter) {}

    /// @inheritdoc BaseLevSwapper
    function angleStaker() public pure override returns (IBorrowStaker) {
        return IBorrowStaker(0xbff202E3Cb58aB0A09b2Eb1D9a50352B9aAf196c);
    }
}