// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWizMagic {
    function getIndex() external view returns (uint256);
    function getRand(uint256 index) external view returns (uint256);
    function getAnotherRand(uint256 firstRand) external view returns (uint256);
}