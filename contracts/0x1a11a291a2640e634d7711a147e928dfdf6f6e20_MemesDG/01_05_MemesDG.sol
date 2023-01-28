// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Memes By David Gersch
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    The Memes By David Gersch    //
//                                 //
//                                 //
/////////////////////////////////////


contract MemesDG is ERC721Creator {
    constructor() ERC721Creator("The Memes By David Gersch", "MemesDG") {}
}