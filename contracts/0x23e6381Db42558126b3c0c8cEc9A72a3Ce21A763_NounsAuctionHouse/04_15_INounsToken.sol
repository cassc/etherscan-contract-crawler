// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

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

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {INounsDescriptorMinimal} from "./INounsDescriptorMinimal.sol";
import {INounsSeeder} from "./INounsSeeder.sol";

interface INounsToken is IERC721 {
    event NounCreated(uint256 indexed tokenId, INounsSeeder.Seed seed);

    event NounBurned(uint256 indexed tokenId);

    event NoundersDAOUpdated(address noundersDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    event MintWhitelistedAddressAdded(address addr);

    event MintWhitelistedAddressRemoved(address addr);

    event DescriptorUpdated(INounsDescriptorMinimal descriptor);

    event DescriptorLocked();

    event SeederUpdated(INounsSeeder seeder);

    event SeederLocked();

    function mint() external returns (uint256);

    function mintTo(address to) external returns (uint256);

    function mintOneOfOne(address to, uint48 oneOfOneId)
        external
        returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setNoundersDAO(address noundersDAO) external;

    function lockMinter() external;

    function setDescriptor(INounsDescriptorMinimal descriptor) external;

    function lockDescriptor() external;

    function setSeeder(INounsSeeder seeder) external;

    function lockSeeder() external;

    function addAddressToWhitelist(address addr)
        external
        returns (bool success);

    function addAddressesToWhitelist(address[] memory addrs)
        external
        returns (bool success);

    function removeAddressFromWhitelist(address addr)
        external
        returns (bool success);

    function removeAddressesFromWhitelist(address[] memory addrs)
        external
        returns (bool success);

    function noundersDAO() external view returns (address);
}