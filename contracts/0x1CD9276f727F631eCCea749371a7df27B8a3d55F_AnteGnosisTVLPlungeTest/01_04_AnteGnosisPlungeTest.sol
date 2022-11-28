pragma solidity ^0.8.0;

import "../AnteTest.sol";
import "../interfaces/IERC20.sol";

// @title Gnosis Plunge Test
contract AnteGnosisTVLPlungeTest is AnteTest("Make sure the TVL is at least 15% of the original TVL") {
    IERC20 private constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 private constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 private constant UST = IERC20(0xa47c8bf37f92aBed4A126BDA807A7b7498661acD);
    IERC20 private constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address private constant GNOSIS_CONTRACT = 0x6F400810b62df8E13fded51bE75fF5393eaa841F;

    uint256 private immutable oldTVL;

    constructor() {
        testedContracts = [GNOSIS_CONTRACT];
        protocolName = "Gnosis";

        oldTVL = getBalances();
    }

    // @return the current tvl
    function getBalances() public view returns (uint256) {
        uint256 usdtBalance = USDT.balanceOf(GNOSIS_CONTRACT);
        uint256 usdcBalance = USDC.balanceOf(GNOSIS_CONTRACT);
        uint256 daiBalance = DAI.balanceOf(GNOSIS_CONTRACT);
        uint256 ustBalance = UST.balanceOf(GNOSIS_CONTRACT);
        uint256 wethBalance = WETH.balanceOf(GNOSIS_CONTRACT);

        // USDC and USDT use 6 decimals. Everything else uses 18. Need to convert it for equal weight.
        usdtBalance = usdtBalance / 10**12;
        usdcBalance = usdcBalance / 10**12;

        return (usdtBalance + usdcBalance + daiBalance + ustBalance + wethBalance);
    }

    // @return if the new tvl is greater than 15% of the old tvl
    function checkTestPasses() public view override returns (bool) {
        return ((getBalances() * 100) / oldTVL > 15);
    }
}