// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SMOLCARTEL
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    BURN&MEME    //
//                 //
//                 //
/////////////////////


contract MEME is ERC1155Creator {
    constructor() ERC1155Creator("SMOLCARTEL", "MEME") {}
}