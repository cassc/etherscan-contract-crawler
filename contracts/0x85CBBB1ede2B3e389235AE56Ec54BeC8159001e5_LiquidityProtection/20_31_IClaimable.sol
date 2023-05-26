// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

/// @title Claimable contract interface
interface IClaimable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}