// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Siberia
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    sbr1    //
//            //
//            //
////////////////


contract sbr1 is ERC721Creator {
    constructor() ERC721Creator("Siberia", "sbr1") {}
}