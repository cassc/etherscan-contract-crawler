// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../CurveLevSwapperLUSDv3CRV.sol";

/// @title ConvexLevSwapperLUSDv3CRV
/// @author Angle Labs, Inc.
/// @notice Implements CurveLevSwapperLUSDv3CRV with a Convex staker
contract ConvexLevSwapperLUSDv3CRV is CurveLevSwapperLUSDv3CRV {
    constructor(
        ICoreBorrow _core,
        IUniswapV3Router _uniV3Router,
        address _oneInch,
        IAngleRouterSidechain _angleRouter
    ) CurveLevSwapperLUSDv3CRV(_core, _uniV3Router, _oneInch, _angleRouter) {}

    /// @inheritdoc BaseLevSwapper
    function angleStaker() public pure override returns (IBorrowStaker) {
        return IBorrowStaker(0x9650821B3555Fe6318586BE997cc0Fb163C35976);
    }
}