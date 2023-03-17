// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MakailaArt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//      __      _    //
//    o'')}____//    //
//     `_/      )    //
//     (_(_/-(_/     //
//                   //
//                   //
///////////////////////


contract MA is ERC721Creator {
    constructor() ERC721Creator("MakailaArt", "MA") {}
}