// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: it_gleam A
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    it_gleam    //
//                //
//                //
////////////////////


contract IGM1 is ERC721Creator {
    constructor() ERC721Creator("it_gleam A", "IGM1") {}
}