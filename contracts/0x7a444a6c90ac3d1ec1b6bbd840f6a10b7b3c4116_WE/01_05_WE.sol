// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    .  ..___                  //
//    |  |[__                   //
//    |/\|[___                  //
//                              //
//                              //
//    uniqueness & diversity    //
//                              //
//                              //
//////////////////////////////////


contract WE is ERC721Creator {
    constructor() ERC721Creator("WE", "WE") {}
}