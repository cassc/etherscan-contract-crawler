// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE ONE #RKT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    The only one.    //
//                     //
//                     //
/////////////////////////


contract HOWL is ERC721Creator {
    constructor() ERC721Creator("THE ONE #RKT", "HOWL") {}
}