// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./IERC721Royalty.sol";

abstract contract ERC721Royalty is ERC2981, IERC721Royalty {}