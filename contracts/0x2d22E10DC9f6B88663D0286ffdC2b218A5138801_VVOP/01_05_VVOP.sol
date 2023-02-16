// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Open VV
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    123-123      //
//                 //
//                 //
//                 //
//    Bawlz.eth    //
//                 //
//                 //
//                 //
/////////////////////


contract VVOP is ERC1155Creator {
    constructor() ERC1155Creator("Open VV", "VVOP") {}
}