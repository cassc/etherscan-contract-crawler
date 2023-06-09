// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

import {IMigrateable} from "../interfaces/IMigrateable.sol";
import {NTConfig, NTComponent} from "./NTConfig.sol";

contract NTMigrator is ReentrancyGuard, Ownable {
    NTConfig config;
    bool migrationOpen;

    function migrateAssets(NTComponent[] memory contracts, uint256[] memory tokenIds) public nonReentrant {
        require(migrationOpen, "Migration is not open");
        require(contracts.length == tokenIds.length, "Arrays must be of equal length.");

        for (uint256 i = 0; i < contracts.length; ++i) {
            IMigrateable migrator = IMigrateable(config.findMigrator(contracts[i]));
            migrator.migrateAsset(_msgSender(), tokenIds[i]);
        }
    }

    constructor(address config_) Ownable() {
        config = NTConfig(config_);
    }

    function setMigrationOpen(bool isOpen) external onlyOwner {
        migrationOpen = isOpen;
    }
}