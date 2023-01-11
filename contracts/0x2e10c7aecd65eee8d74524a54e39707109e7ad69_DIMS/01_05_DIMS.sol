// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dimitri Bello
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Editions    //
//                //
//                //
////////////////////


contract DIMS is ERC721Creator {
    constructor() ERC721Creator("Dimitri Bello", "DIMS") {}
}