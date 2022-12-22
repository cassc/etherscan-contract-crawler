// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IOwnable {
    error RecipientAddressIsZeroAddress();

    error SenderIsNotOwner();

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);
}