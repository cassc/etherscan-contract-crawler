// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 761026 (Not) Fake meme
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    761026     //
//               //
//               //
///////////////////


contract NF761026 is ERC1155Creator {
    constructor() ERC1155Creator("761026 (Not) Fake meme", "NF761026") {}
}