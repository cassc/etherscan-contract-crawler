// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: An1ne
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//                     //
//                     //
//                     //
//                     //
//    An1NE            //
//                     //
//                     //
//                     //
/////////////////////////


contract An1 is ERC721Creator {
    constructor() ERC721Creator("An1ne", "An1") {}
}