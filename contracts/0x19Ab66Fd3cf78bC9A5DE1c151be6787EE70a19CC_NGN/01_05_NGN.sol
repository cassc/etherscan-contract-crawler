// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NotGen
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//    NotGen collection by Akashi30 is exploring generative art in different styles.    //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract NGN is ERC721Creator {
    constructor() ERC721Creator("NotGen", "NGN") {}
}