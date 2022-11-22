// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * Copyright (c) 2022 Mighty Bear Games
 */

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IBigBearSyndicate is IERC721Upgradeable {
	function mint(address to, uint256 tokenId) external;
}