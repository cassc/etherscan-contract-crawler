// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IFormula {
    function getTokenPrice(uint256 _formulaType, address _collectionAddress) external view returns (uint256);
}