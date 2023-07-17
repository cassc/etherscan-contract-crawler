// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../AnteTest.sol";
import "../interfaces/IERC20.sol";

/// @title Curve 3Pool Distribution Test
/// @notice Ensure USDC, USDT, DAI tokens are each < 90% of Curve USD 3Pool's total token balance.
contract AnteCurveThreePoolDistributionTest is AnteTest("Ensure USDC, USDT, DAI token balances are each < 90% of Curve 3Pool token balance") {
    address private constant CURVE_THREE_POOL_ADDRESS = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address private constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    IERC20 private constant USDC = IERC20(USDC_ADDRESS);
    IERC20 private constant USDT = IERC20(USDT_ADDRESS);
    IERC20 private constant DAI = IERC20(DAI_ADDRESS);

    constructor() {
        testedContracts = [CURVE_THREE_POOL_ADDRESS];
        protocolName = "Curve";
    }

    /// @return true if the balances of each token are < 90%
    function checkTestPasses() public view override returns (bool) {
        return
            isLessThanNinety(
                USDC.balanceOf(CURVE_THREE_POOL_ADDRESS),
                USDT.balanceOf(CURVE_THREE_POOL_ADDRESS),
                DAI.balanceOf(CURVE_THREE_POOL_ADDRESS) / 1e12 // DAI has 18 decimals, so divide to reduce to 6
            );
    }

    /// @dev Function used for unit testing to ensure the input and output is correct
    /// @param usdc The amount of USDC in the pool
    /// @param usdt The amount of USDT in the pool
    /// @param dai The amount of DAI in the pool
    /// @return true if usdc, usdt, and dai are each < 90% of their sum.
    function isLessThanNinety(
        uint256 usdc,
        uint256 usdt,
        uint256 dai
    ) public pure returns (bool) {
        uint256 totalSupply = usdc + usdt + dai;
        uint256 multiplier = 100;
        uint256 threshold = 90;
        uint256 usdcPercent = usdc * multiplier / totalSupply;
        uint256 usdtPercent = usdt * multiplier / totalSupply;
        uint256 daiPercent = dai * multiplier / totalSupply;

        return (usdcPercent < threshold && usdtPercent < threshold && daiPercent < threshold);
    }
}