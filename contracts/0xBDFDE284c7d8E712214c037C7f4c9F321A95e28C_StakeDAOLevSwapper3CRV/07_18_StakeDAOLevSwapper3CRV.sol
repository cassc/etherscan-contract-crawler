// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../CurveLevSwapper3CRV.sol";

/// @title StakeDAOLevSwapper3CRV
/// @author Angle Labs, Inc.
/// @notice Implements CurveLevSwapper3CRV with a StakeDAO staker
contract StakeDAOLevSwapper3CRV is CurveLevSwapper3CRV {
    constructor(
        ICoreBorrow _core,
        IUniswapV3Router _uniV3Router,
        address _oneInch,
        IAngleRouterSidechain _angleRouter
    ) CurveLevSwapper3CRV(_core, _uniV3Router, _oneInch, _angleRouter) {}

    /// @inheritdoc BaseLevSwapper
    function angleStaker() public pure override returns (IBorrowStaker) {
        return IBorrowStaker(0xe80298eE8F54a5e1b0448bC2EE844901344469bc);
    }
}