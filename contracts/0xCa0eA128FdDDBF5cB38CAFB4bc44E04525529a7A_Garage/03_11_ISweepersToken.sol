// SPDX-License-Identifier: MIT

/// @title Interface for SweepersToken



pragma solidity ^0.8.6;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { ISweepersDescriptor } from './ISweepersDescriptor.sol';
import { ISweepersSeeder } from './ISweepersSeeder.sol';

interface ISweepersToken is IERC721 {
    event SweeperCreated(uint256 indexed tokenId, ISweepersSeeder.Seed seed);

    event SweeperBurned(uint256 indexed tokenId);

    event SweeperStakedAndLocked(uint256 indexed tokenId, uint256 timestamp);

    event SweeperUnstakedAndUnlocked(uint256 indexed tokenId, uint256 timestamp);

    event SweepersTreasuryUpdated(address sweepersTreasury);

    event MinterUpdated(address minter);

    event MinterLocked();

    event GarageUpdated(address garage);

    event DescriptorUpdated(ISweepersDescriptor descriptor);

    event DescriptorLocked();

    event SeederUpdated(ISweepersSeeder seeder);

    event SeederLocked();

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setSweepersTreasury(address sweepersTreasury) external;

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(ISweepersDescriptor descriptor) external;

    function lockDescriptor() external;

    function setSeeder(ISweepersSeeder seeder) external;

    function lockSeeder() external;

    function stakeAndLock(uint256 tokenId) external returns (uint8);

    function unstakeAndUnlock(uint256 tokenId) external;

    function setGarage(address _garage, bool _flag) external;

    function isStakedAndLocked(uint256 _id) external view returns (bool);
}