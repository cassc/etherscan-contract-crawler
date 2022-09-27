// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Great Jack
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    It's the greatness    //
//                          //
//                          //
//////////////////////////////


contract TGJ is ERC721Creator {
    constructor() ERC721Creator("The Great Jack", "TGJ") {}
}