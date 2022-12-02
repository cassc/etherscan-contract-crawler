// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IUserFlashclaimRegistry {
    function createReceiver() external;

    function getUserReceivers(address user) external view returns (address);
}