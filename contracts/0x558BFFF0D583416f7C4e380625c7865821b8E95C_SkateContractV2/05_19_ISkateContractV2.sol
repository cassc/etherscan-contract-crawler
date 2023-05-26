// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Gnar

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

pragma solidity 0.8.6;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IGnarDescriptorV2} from "./IGNARDescriptorV2.sol";
import {IGnarSeederV2} from "./IGNARSeederV2.sol";

interface ISkateContractV2 is IERC721 {
    event GnarCreated(uint256 indexed tokenId, IGnarSeederV2.Seed seed);

    event GnarBurned(uint256 indexed tokenId);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(IGnarDescriptorV2 descriptor);

    event DescriptorLocked();

    event SeederUpdated(IGnarSeederV2 seeder);

    event SeederLocked();

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(IGnarDescriptorV2 descriptor) external;

    function lockDescriptor() external;

    function setSeeder(IGnarSeederV2 seeder) external;

    function lockSeeder() external;
}