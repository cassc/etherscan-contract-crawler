// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: hornys
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    kanoka    //
//              //
//              //
//////////////////


contract hornys is ERC721Creator {
    constructor() ERC721Creator("hornys", "hornys") {}
}