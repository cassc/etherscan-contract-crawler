// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Complicated
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    CMPLCTD33    //
//                 //
//                 //
/////////////////////


contract COMP is ERC721Creator {
    constructor() ERC721Creator("Complicated", "COMP") {}
}