// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IOwnable {
    function owner() external view returns (address);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwnership(address newOwner) external;
}