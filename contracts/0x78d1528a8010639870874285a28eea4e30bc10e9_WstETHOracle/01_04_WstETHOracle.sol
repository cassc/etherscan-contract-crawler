// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IWstETH {
    function stETH() external view returns(address);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
}
interface IMasterVault {
    function previewRedeem(uint256 shares) external view returns (uint256);
}

contract WstETHOracle is Initializable{

    AggregatorV3Interface internal priceFeed; // 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8 stETH/USD
    IWstETH internal wstETH;
    IMasterVault internal masterVault;

    function initialize(address _aggregatorAddress, address _wstETH, IMasterVault _masterVault) external initializer {
        priceFeed = AggregatorV3Interface(_aggregatorAddress);
        wstETH = IWstETH(_wstETH);
        masterVault = _masterVault;
    }

    /**
     * Returns the latest price
     */
    function peek() public view returns (bytes32, bool) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        if (price < 0) {
            return (0, false);
        }

        // Get stETH equivalent to 1wstETH and multiply with stETH price
        uint256 stETH = wstETH.getStETHByWstETH(1e18);
        uint256 wstETHPrice = (stETH * uint(price * (10**10))) / 1e18;

        // Get wstETH equivalent to 1share in MasterVault
        uint256 wstETH = masterVault.previewRedeem(1e18);
        uint256 sharePrice = (wstETHPrice * wstETH) / 1e18;

        return (bytes32(sharePrice), true);
    }
}