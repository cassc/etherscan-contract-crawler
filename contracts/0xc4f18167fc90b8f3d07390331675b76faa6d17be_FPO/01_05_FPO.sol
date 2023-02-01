// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FAKE PEPEAR ONE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    MAJIN BOG    //
//                 //
//                 //
/////////////////////


contract FPO is ERC721Creator {
    constructor() ERC721Creator("FAKE PEPEAR ONE", "FPO") {}
}