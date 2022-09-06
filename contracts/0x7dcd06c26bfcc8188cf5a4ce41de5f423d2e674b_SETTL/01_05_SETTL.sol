// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Settlements
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Settlement by indie    //
//                           //
//                           //
///////////////////////////////


contract SETTL is ERC721Creator {
    constructor() ERC721Creator("Settlements", "SETTL") {}
}