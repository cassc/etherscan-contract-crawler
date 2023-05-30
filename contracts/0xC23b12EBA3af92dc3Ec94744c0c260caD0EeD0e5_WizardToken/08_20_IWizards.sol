// SPDX-License-Identifier: GPL-3.0

/// @title Wizards ERC-721 token

pragma solidity ^0.8.6;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ISeeder} from "./seeder/ISeeder.sol";
import {IDescriptor} from "./descriptor/IDescriptor.sol";

interface IWizardToken is IERC721 {
    event SupplyUpdated(uint256 indexed supply);

    event WizardCreated(uint256 indexed tokenId, ISeeder.Seed seed);

    event WizardBurned(uint256 indexed tokenId);

    event CreatorsDAOUpdated(address creatorsDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(IDescriptor descriptor);

    event DescriptorLocked();

    event SeederUpdated(ISeeder seeder);

    event SeederLocked();

    function mint() external returns (uint256);

    function mintOneOfOne(uint48 oneOfOneId) external returns (uint256, bool);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setCreatorsDAO(address creatorsDAO) external;

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(IDescriptor descriptor) external;

    function lockDescriptor() external;

    function setSeeder(ISeeder seeder) external;

    function lockSeeder() external;

    function setSupply(uint256 supply) external;
}