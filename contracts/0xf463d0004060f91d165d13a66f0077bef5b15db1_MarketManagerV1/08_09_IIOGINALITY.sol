// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./extensions/IERC721RoyaltiesStorage.sol";

interface IIOGINALITY is IERC721, IERC721RoyaltiesStorage {}