// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../dependencies/openzeppelin/IERC20.sol";
import "./IBVault.sol";

interface IBManagedPool {
    function getSwapEnabled() external view returns (bool);

    function getSwapFeePercentage() external view returns (uint256);

    function getNormalizedWeights() external view returns (uint256[] memory);

    function getPoolId() external view returns (bytes32);

    function getVault() external view returns (IBVault);

    function getOwner() external view returns (address);
}