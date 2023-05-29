// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kingyo in the Park
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Some life film.            //
//    Some bipolar flow.         //
//    Some dramatic dialogue.    //
//                               //
//                               //
///////////////////////////////////


contract KP is ERC721Creator {
    constructor() ERC721Creator("Kingyo in the Park", "KP") {}
}