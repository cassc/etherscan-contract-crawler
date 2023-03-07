// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sero
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    Sero    //
//            //
//            //
////////////////


contract Sero is ERC721Creator {
    constructor() ERC721Creator("Sero", "Sero") {}
}