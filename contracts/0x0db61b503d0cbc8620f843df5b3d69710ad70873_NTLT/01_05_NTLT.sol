// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Naturlichturism
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    nat. 1/1s.    //
//                  //
//                  //
//////////////////////


contract NTLT is ERC721Creator {
    constructor() ERC721Creator("Naturlichturism", "NTLT") {}
}