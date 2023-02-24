// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../../CurveLevSwapper2Tokens.sol";

/// @title CurveLevSwapperLUSDv3CRV
/// @author Angle Labs, Inc
/// @notice Implements a leverage swapper to gain/reduce exposure to the LUSD-3CRV Curve LP token
/// with no granularity on 3CRV
contract CurveLevSwapperLUSDv3CRV is CurveLevSwapper2Tokens {
    constructor(
        ICoreBorrow _core,
        IUniswapV3Router _uniV3Router,
        address _oneInch,
        IAngleRouterSidechain _angleRouter
    ) CurveLevSwapper2Tokens(_core, _uniV3Router, _oneInch, _angleRouter) {}

    /// @inheritdoc BaseLevSwapper
    function angleStaker() public view virtual override returns (IBorrowStaker) {
        return IBorrowStaker(address(0));
    }

    /// @inheritdoc CurveLevSwapper2Tokens
    function tokens() public pure override returns (IERC20[2] memory) {
        return [IERC20(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0), IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490)];
    }

    /// @inheritdoc CurveLevSwapper2Tokens
    function metapool() public pure override returns (IMetaPool2) {
        return IMetaPool2(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);
    }

    /// @inheritdoc CurveLevSwapper2Tokens
    function lpToken() public pure override returns (IERC20) {
        return IERC20(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);
    }
}