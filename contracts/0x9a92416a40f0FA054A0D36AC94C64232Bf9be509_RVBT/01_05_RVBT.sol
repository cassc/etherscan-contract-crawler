// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RVBT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    TEST    //
//            //
//            //
////////////////


contract RVBT is ERC721Creator {
    constructor() ERC721Creator("RVBT", "RVBT") {}
}