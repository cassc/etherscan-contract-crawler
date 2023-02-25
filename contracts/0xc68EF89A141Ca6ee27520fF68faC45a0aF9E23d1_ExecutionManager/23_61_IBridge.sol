// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IBridge {
    function activeOutbox() external view returns (address);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);

    function isNitroReady() external view returns (uint256);
}