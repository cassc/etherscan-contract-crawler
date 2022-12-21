// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oty 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Oty 1/1s    //
//                //
//                //
////////////////////


contract OTY1 is ERC721Creator {
    constructor() ERC721Creator("Oty 1/1s", "OTY1") {}
}