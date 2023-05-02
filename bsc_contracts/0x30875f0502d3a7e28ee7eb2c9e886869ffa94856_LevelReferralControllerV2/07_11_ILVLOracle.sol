// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ILVLOracle {
    function update() external;

    function lastTWAP() external view returns (uint256);

    function getCurrentTWAP() external view returns (uint256);
}