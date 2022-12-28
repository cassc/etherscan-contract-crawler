// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Switchback
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Switchback    //
//                  //
//                  //
//////////////////////


contract SWBK is ERC721Creator {
    constructor() ERC721Creator("Switchback", "SWBK") {}
}