// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TE’s 1st contract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    This is TE’s first contact    //
//                                  //
//                                  //
//////////////////////////////////////


contract TEC is ERC721Creator {
    constructor() ERC721Creator(unicode"TE’s 1st contract", "TEC") {}
}