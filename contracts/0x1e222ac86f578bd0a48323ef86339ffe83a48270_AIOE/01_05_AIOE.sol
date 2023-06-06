// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AIED OE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//    borovik - AIOE                                                                    //
//                                                                                      //
//    I make 1 NFT per day and mint it. I started July 12th 2022.                       //
//    I decided to launch my first OE. This piece is not part of my AIED collection.    //
//    The purpose of this OE is to expand my collector base!                            //
//    Follow me on twitter: @3orovik                                                    //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract AIOE is ERC721Creator {
    constructor() ERC721Creator("AIED OE", "AIOE") {}
}