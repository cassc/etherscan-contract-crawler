// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Values
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                        //
//                                                                                                        //
//    The Values are an attempt to bring the values we would like to see into spaces that we inhabit.     //
//                                                                                                        //
//    The Values are building off of the CC0 project “The Memes” By 6529                                  //
//                                                                                                        //
//    The Values NFTs will fund the artist, the creators, and the Open Metaverse initiative               //
//                                                                                                        //
//                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Val1 is ERC1155Creator {
    constructor() ERC1155Creator("The Values", "Val1") {}
}