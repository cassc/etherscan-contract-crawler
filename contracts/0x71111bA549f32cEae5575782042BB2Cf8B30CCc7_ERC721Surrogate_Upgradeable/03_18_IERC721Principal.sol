// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// solhint-disable-next-line no-empty-blocks
interface IERC721Principal is IERC721Metadata, IERC721Enumerable {}