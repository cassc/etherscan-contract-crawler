// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IRegistry {
    struct Entry {
        bytes32 id; // stakeId
        uint256 value; // amount
    }

    function migrateWritePermission(address contractRepresentitive) external;

    function createEntry(
        address owner,
        bytes32 id,
        uint256 value
    ) external;

    function readEntry(address owner, bytes32 id) external view returns (uint256);

    function readAllEntries(address owner) external view returns (bytes32[] memory id, uint256[] memory value);

    function updateEntry(
        address owner,
        bytes32 id,
        uint256 value
    ) external;

    function deleteEntry(address owner, bytes32 id) external;
}