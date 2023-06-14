// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AOwnerProxy {
    function ownerOf(bytes32 hash) external view returns (address);
    function initOwnerOf(bytes32 hash, address addr) external returns (bool);
    function transferOwnership(bytes32 hash, address newOwner) external;
}