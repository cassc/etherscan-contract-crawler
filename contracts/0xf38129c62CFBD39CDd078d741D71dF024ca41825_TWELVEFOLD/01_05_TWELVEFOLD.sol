// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TwelveFold
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    TwelveFold    //
//                  //
//                  //
//////////////////////


contract TWELVEFOLD is ERC721Creator {
    constructor() ERC721Creator("TwelveFold", "TWELVEFOLD") {}
}