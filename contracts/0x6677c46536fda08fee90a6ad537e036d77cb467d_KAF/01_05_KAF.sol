// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: & Friends
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    * **** ***    //
//                  //
//                  //
//////////////////////


contract KAF is ERC721Creator {
    constructor() ERC721Creator("& Friends", "KAF") {}
}