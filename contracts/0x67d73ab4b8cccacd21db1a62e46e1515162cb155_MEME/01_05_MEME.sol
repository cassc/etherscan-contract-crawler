// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: No Art, Just Memes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    NAJM2023    //
//                //
//                //
////////////////////


contract MEME is ERC721Creator {
    constructor() ERC721Creator("No Art, Just Memes", "MEME") {}
}