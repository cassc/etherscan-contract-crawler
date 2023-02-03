// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

contract VersionId {
    uint256 constant public versionId = uint256(keccak256("2"));
}