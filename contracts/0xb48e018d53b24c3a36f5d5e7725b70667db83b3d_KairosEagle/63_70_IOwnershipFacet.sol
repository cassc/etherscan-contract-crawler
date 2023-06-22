// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IOwnershipFacet {
    function transferOwnership(address _newOwner) external;

    function owner() external view returns (address owner_);
}