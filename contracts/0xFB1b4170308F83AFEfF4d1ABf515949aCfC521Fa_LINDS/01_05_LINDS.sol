// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: For Linds
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    With Love - Derek    //
//                         //
//                         //
/////////////////////////////


contract LINDS is ERC721Creator {
    constructor() ERC721Creator("For Linds", "LINDS") {}
}