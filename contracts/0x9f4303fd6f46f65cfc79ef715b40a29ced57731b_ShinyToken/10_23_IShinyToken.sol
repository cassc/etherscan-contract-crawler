// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShinyToken

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IShinyDescriptor } from './IShinyDescriptor.sol';
import { IShinySeeder } from './IShinySeeder.sol';

interface IShinyToken is IERC721 {
    event ShinyCreated(uint256 indexed tokenId, IShinySeeder.Seed seed, uint16 shinyChanceBasisPoints);

    event ShinyReconfigured(uint256 indexed tokenId, IShinySeeder.Seed seed, uint256 reconfigurationCount);

    event ShinyRevealed(uint256 tokenId, bool isShiny);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(IShinyDescriptor descriptor);

    event DescriptorLocked();

    event SeederUpdated(IShinySeeder seeder);

    event SeederLocked();

    event ContractMetadataUpdated(string contractURI);

    function mint(address to, uint16 shinyChanceBasisPoints) external returns (uint256);

    function reconfigureShiny(uint256 tokenId, address owner, IShinySeeder.Seed memory newSeed) external returns (IShinySeeder.Seed memory);

    function revealShiny(uint256 tokenId) external returns (bool);

    function tokenShinyState(uint256 tokenId) external returns (bool);

    function dataURI(uint256 tokenId) external returns (string memory);

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(IShinyDescriptor descriptor) external;

    function lockDescriptor() external;

    function setSeeder(IShinySeeder seeder) external;

    function lockSeeder() external;

    function totalVotingUnits() external returns (uint256);
}