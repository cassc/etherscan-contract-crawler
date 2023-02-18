// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IInvictusOrderApplication {
    error InvalidSender();
    error AlreadyMinted();
    error AddressZero();
    error InvalidAddress();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}