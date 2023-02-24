// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../CurveLevSwapperLUSDv3CRV.sol";

/// @title StakeDAOLevSwapperLUSDv3CRV
/// @author Angle Labs, Inc.
/// @notice Implements CurveLevSwapperLUSDv3CRV with a StakeDAO staker
contract StakeDAOLevSwapperLUSDv3CRV is CurveLevSwapperLUSDv3CRV {
    constructor(
        ICoreBorrow _core,
        IUniswapV3Router _uniV3Router,
        address _oneInch,
        IAngleRouterSidechain _angleRouter
    ) CurveLevSwapperLUSDv3CRV(_core, _uniV3Router, _oneInch, _angleRouter) {}

    /// @inheritdoc BaseLevSwapper
    function angleStaker() public pure override returns (IBorrowStaker) {
        return IBorrowStaker(0x97F0A7954904a7357D814ACE2896021496e5f321);
    }
}