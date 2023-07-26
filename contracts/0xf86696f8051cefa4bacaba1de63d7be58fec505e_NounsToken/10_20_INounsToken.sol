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

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IERC2981 } from '@openzeppelin/contracts/interfaces/IERC2981.sol';
import { INounsDescriptor } from './INounsDescriptor.sol';
import { INounsSeeder } from './INounsSeeder.sol';

interface INounsToken is IERC721, IERC2981 {
    event BeachBumCreated(uint256 indexed tokenId, INounsSeeder.Seed seed);

    event AdminUpdated(address minter);

    event AdminLocked();

    function withdraw() external;

    function withdrawERC20Balance(address erc20ContractAddress) external;

    function mint(address account) external payable returns (uint256);

    function mintBatch(address account, uint256 quantity) external payable returns (uint256, uint256);

    function redeem(address account, bytes32[] calldata proof) external returns (uint256);

    function dataURI(uint256 tokenId) external returns (string memory);

    function setRoot(bytes32 merkleRoot, uint256 quantity) external;

    function setMintFee(uint256 fee) external;

    function toggleMint() external;

    function setAdmin(address minter) external;

    function setRoyalty(uint256 royaltyBasis) external;

    function lockAdmin() external;
}