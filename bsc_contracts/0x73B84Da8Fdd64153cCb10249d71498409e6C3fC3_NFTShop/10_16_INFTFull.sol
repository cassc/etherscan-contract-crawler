// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./INFT.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Full interface of NFT, wasn't used as interface for NFT bcs of usage of upgradable base classes
 */
interface INFTFull is INFT, IERC721 {

}