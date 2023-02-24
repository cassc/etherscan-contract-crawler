// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../../CurveLevSwapper3Tokens.sol";

/// @title CurveLevSwapper3CRV
/// @author Angle Labs, Inc.
/// @dev Implementation of `CurveLevSwapper3Tokens` for the 3CRV pool
contract CurveLevSwapper3CRV is CurveLevSwapper3Tokens {
    constructor(
        ICoreBorrow _core,
        IUniswapV3Router _uniV3Router,
        address _oneInch,
        IAngleRouterSidechain _angleRouter
    ) CurveLevSwapper3Tokens(_core, _uniV3Router, _oneInch, _angleRouter) {}

    /// @inheritdoc BaseLevSwapper
    function angleStaker() public view virtual override returns (IBorrowStaker) {
        return IBorrowStaker(address(0));
    }

    /// @inheritdoc CurveLevSwapper3Tokens
    function tokens() public pure override returns (IERC20[3] memory) {
        return [
            IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F),
            IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
            IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7)
        ];
    }

    /// @inheritdoc CurveLevSwapper3Tokens
    function metapool() public pure override returns (IMetaPool3) {
        return IMetaPool3(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    }

    /// @inheritdoc CurveLevSwapper3Tokens
    function lpToken() public pure override returns (IERC20) {
        return IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    }
}