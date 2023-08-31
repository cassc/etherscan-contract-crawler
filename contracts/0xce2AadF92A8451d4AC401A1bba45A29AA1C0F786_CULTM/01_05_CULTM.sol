// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cult's Memes of Psyop
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    CULT'S MEMES OF THE PSYOP    //
//                                 //
//                                 //
/////////////////////////////////////


contract CULTM is ERC721Creator {
    constructor() ERC721Creator("Cult's Memes of Psyop", "CULTM") {}
}