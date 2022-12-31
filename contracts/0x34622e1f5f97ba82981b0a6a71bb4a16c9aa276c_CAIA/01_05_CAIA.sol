// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crypto AI Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//    AI x Crypto                                               //
//    Comments on the recent events through the lens of AI.     //
//    Unique. Vibrant.                                          //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract CAIA is ERC721Creator {
    constructor() ERC721Creator("Crypto AI Art", "CAIA") {}
}