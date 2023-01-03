// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: it_gleam C
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    it_gleam    //
//                //
//                //
////////////////////


contract IGM3 is ERC721Creator {
    constructor() ERC721Creator("it_gleam C", "IGM3") {}
}