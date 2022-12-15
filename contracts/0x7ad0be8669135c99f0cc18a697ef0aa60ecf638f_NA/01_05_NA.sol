// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Numbers Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Numbers Art    //
//                   //
//                   //
///////////////////////


contract NA is ERC721Creator {
    constructor() ERC721Creator("Numbers Art", "NA") {}
}