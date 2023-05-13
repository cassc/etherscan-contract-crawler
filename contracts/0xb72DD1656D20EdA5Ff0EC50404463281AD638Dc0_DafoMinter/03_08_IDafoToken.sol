// SPDX-License-Identifier: GPL-3.0

/// @title Interface for DafoToken

pragma solidity ^0.8.6;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IDafoDescriptor} from './IDafoDescriptor.sol';
import {IDafoCustomizer} from './IDafoCustomizer.sol';

interface IDafoToken is IERC721 {
    event DafoCreated(uint256 indexed tokenId, IDafoCustomizer.CustomInput customInput);

    event DafoBurned(uint256 indexed tokenId);

    event DafoundersDAOUpdated(address dafoundersDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    event EarlyAccessMinterLocked();

    event DescriptorUpdated(IDafoDescriptor descriptor);

    event DescriptorLocked();

    event CustomizerUpdated(IDafoCustomizer customizer);

    event CustomizerLocked();

    function mint(IDafoCustomizer.CustomInput memory customizer, address to) external returns (uint256);

    function burn(uint256 tokenId) external;

    function exists(uint256 tokenId) external returns (bool);

    function dataURI(uint256 tokenId) external returns (string memory);

    function setDafoundersDAO(address dafoundersDAO) external;

    function setMinter(address minter) external;

    function lockMinter() external;

    function lockEarlyAccessMinter() external;

    function setDescriptor(IDafoDescriptor descriptor) external;

    function lockDescriptor() external;

    function setCustomizer(IDafoCustomizer customizer) external;

    function lockCustomizer() external;

    function findNextAvailable(uint16 representative) external view returns (uint16);
}