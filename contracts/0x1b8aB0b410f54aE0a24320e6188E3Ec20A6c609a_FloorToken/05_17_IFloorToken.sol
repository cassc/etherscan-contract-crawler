// SPDX-License-Identifier: GPL-3.0

/// @title Interface for FloorToken

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                            *
*    8888888888 888      .d88888b.   .d88888b.  8888888b.    *
*    888        888     d88P" "Y88b d88P" "Y88b 888   Y88b   *
*    888        888     888     888 888     888 888    888   *
*    8888888    888     888     888 888     888 888   d88P   *
*    888        888     888     888 888     888 8888888P"    *
*    888        888     888     888 888     888 888 T88b     *
*    888        888     Y88b. .d88P Y88b. .d88P 888  T88b    *
*    888        88888888 "Y88888P"   "Y88888P"  888   T88b   *
*                                                            *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

pragma solidity ^0.8.6;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IFloorDescriptor } from './IFloorDescriptor.sol';

interface IFloorToken is IERC721 {
    event DataURIToggled(bool enabled);

    event FloorCreated(uint256 indexed tokenId, uint16 size);

    event FloorBurned(uint256 indexed tokenId);

    event FloorsDAOUpdated(address floorsDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(IFloorDescriptor descriptor);

    event DescriptorLocked();

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setFloorsDAO(address floorsDAO) external;

    function setMinter(address minter) external;

    function setDescriptor(IFloorDescriptor descriptor) external;

    function lockDescriptor() external;

    function lockMinter() external;
}