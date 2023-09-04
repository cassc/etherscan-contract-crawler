// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ILendingAddressProvider {
    event LendingAdded(address indexed lending);

    event LendingRemoved(address indexed lending);

    function isLending(address) external view returns (bool);

    function addLending(address _lending) external;
}