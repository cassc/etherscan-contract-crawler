// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import {INomoNounsDescriptor} from "./INomoNounsDescriptor.sol";
import {INounsSeeder} from "../../nouns-contracts/NounsDescriptorV2/contracts/interfaces/INounsSeeder.sol";

interface INomoNounsSeeder {
    struct Seed {
        uint40 nounId;
        uint40 background;
        uint40 body;
        uint40 accessory;
        uint40 head;
        uint40 glasses;
    }

    function generateSeed(
        uint256 nounId,
        uint256 blockNumber,
        INomoNounsDescriptor descriptor
    ) external view returns (Seed memory);
}