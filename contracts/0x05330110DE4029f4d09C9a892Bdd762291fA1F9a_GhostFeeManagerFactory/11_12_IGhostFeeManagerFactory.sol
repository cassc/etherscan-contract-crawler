// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGhostFeeManagerFactory {
    event CreateFeeManager(string name, address creator);

    function WETH() external view returns (address);

    function getOwner() external view returns (address);

    function adminFeeRatio() external view returns (uint256);

    function totalRatio() external view returns (uint256);

    function changeFee(uint256, uint256) external;

    function createFeeManager(string memory) external;

    function getFeeManagerAddress() external view returns (address[] memory);

    function recoverTokens() external;

    function feeDistribute() external;

    function getNetAndFeeBalance(uint256) external view returns (uint256, uint256);
}