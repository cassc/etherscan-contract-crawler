// SPDX-License-Identifier: GPL-3.0

/// @title Interface for PoopToken

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

import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import { INounsDescriptor } from './INounsDescriptor.sol';
import { INounsSeeder } from './INounsSeeder.sol';

interface IPoopToken is IERC1155 {
    event NounCreated(uint256 indexed tokenId);

    event NounBurned(uint256 indexed tokenId);

    event LilGoblinKingsUpdated(address lilgoblinkings);

    event MinterUpdated(address minter);

    event MinterLocked();

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function setLilGoblinKings(address lilgoblinkings) external;

    function setMinter(address minter) external;

    function lockMinter() external;
}