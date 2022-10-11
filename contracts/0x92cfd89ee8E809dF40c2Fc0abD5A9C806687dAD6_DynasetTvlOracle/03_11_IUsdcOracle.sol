// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IUsdcOracle {
    function tokenUsdcValue(address token, uint256 amount) external view 
        returns (uint256 usdcValue, uint256 oldestObservation);
    function getPrice(address base, address quote) external view 
        returns (uint256 value, uint256 oldestObservation);
    function canUpdateTokenPrices() external pure 
        returns (bool);
    function updateTokenPrices(address[] memory tokens) external 
        returns (bool[] memory updates);
}