// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGhostSharePotFactory {
    event CreatePot(string name, address creator);

    function WETH() external view returns (address);

    function getOwner() external view returns (address);

    function adminFeeRatio() external view returns (uint256);

    function totalRatio() external view returns (uint256);

    function changeFee(uint256, uint256) external;

    function createPot(string memory, address) external;

    function getPotAddress() external view returns (address[] memory);

    function recoverTokens(address) external;

    function feeDistribute() external;

    function getNetAndFeeBalance(uint256) external view returns (uint256, uint256);
}