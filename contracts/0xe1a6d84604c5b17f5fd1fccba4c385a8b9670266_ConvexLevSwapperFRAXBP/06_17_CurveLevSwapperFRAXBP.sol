// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../../CurveLevSwapper2Tokens.sol";

/// @title CurveLevSwapperFRAXBP
/// @author Angle Labs, Inc
/// @notice Implements a leverage swapper to gain/reduce exposure to the FRAXBP Curve LP token
contract CurveLevSwapperFRAXBP is CurveLevSwapper2Tokens {
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
        return [IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e), IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)];
    }

    /// @inheritdoc CurveLevSwapper2Tokens
    function metapool() public pure override returns (IMetaPool2) {
        return IMetaPool2(0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2);
    }

    /// @inheritdoc CurveLevSwapper2Tokens
    function lpToken() public pure override returns (IERC20) {
        return IERC20(0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC);
    }
}