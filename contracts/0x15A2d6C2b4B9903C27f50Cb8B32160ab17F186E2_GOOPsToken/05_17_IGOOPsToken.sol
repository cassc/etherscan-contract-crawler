// SPDX-License-Identifier: GPL-3.0



pragma solidity ^0.8.6;

import { IERC721 } from './IERC721.sol';
import { IGOOPsDescriptor } from './IGOOPsDescriptor.sol';
import { IGOOPsSeeder } from './IGOOPsSeeder.sol';

interface IGOOPsToken is IERC721 {
    event GOOPCreated(uint256 indexed tokenId, IGOOPsSeeder.Seed seed);

    event GOOPBurned(uint256 indexed tokenId);

    event DescriptorUpdated(IGOOPsDescriptor descriptor);

    event DescriptorLocked();

    event SeederUpdated(IGOOPsSeeder seeder);

    event SeederLocked();

    function mint(uint256 num_tokens) external payable;

    function burn(uint256 tokenId) external;

    function setDescriptor(IGOOPsDescriptor descriptor) external;

    function lockDescriptor() external;

    function setSeeder(IGOOPsSeeder seeder) external;

    function lockSeeder() external;



}