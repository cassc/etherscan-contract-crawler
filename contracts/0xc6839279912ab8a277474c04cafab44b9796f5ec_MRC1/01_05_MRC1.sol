// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MRC Arte 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    ARTE IS ART    //
//                   //
//                   //
///////////////////////


contract MRC1 is ERC721Creator {
    constructor() ERC721Creator("MRC Arte 1/1s", "MRC1") {}
}