// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BURNINGMAN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    PART 1 - BURNINGMAN    //
//                           //
//                           //
///////////////////////////////


contract BMAN is ERC1155Creator {
    constructor() ERC1155Creator("BURNINGMAN", "BMAN") {}
}