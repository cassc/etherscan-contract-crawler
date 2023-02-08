// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Championship Squares
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    |-----------|    //
//    |  Squares. |    //
//    |-----------|    //
//                     //
//                     //
//                     //
/////////////////////////


contract CS is ERC721Creator {
    constructor() ERC721Creator("Championship Squares", "CS") {}
}