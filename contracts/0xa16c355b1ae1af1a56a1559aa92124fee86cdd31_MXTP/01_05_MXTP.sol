// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MixTape
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    by whatisiana    //
//                     //
//                     //
/////////////////////////


contract MXTP is ERC721Creator {
    constructor() ERC721Creator("MixTape", "MXTP") {}
}