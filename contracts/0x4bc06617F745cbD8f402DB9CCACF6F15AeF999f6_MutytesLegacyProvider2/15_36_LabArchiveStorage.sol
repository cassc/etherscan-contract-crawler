// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant LAB_ARCHIVE_STORAGE_SLOT = keccak256("ethernia.lab.archive.storage");

struct LabArchiveStorage {
    mapping(uint256 => string) mutyteNames;
    mapping(string => uint256) mutyteByName;
    mapping(uint256 => string) mutyteDescriptions;
    mapping(uint256 => string) mutationNames;
    mapping(uint256 => string) mutationDescriptions;
}

function labArchiveStorage() pure returns (LabArchiveStorage storage ls) {
    bytes32 slot = LAB_ARCHIVE_STORAGE_SLOT;
    assembly {
        ls.slot := slot
    }
}