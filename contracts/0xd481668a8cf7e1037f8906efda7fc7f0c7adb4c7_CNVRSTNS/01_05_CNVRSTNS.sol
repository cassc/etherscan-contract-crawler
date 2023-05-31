// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Conversations with Son
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Conversations with Son    //
//                              //
//                              //
//////////////////////////////////


contract CNVRSTNS is ERC721Creator {
    constructor() ERC721Creator("Conversations with Son", "CNVRSTNS") {}
}