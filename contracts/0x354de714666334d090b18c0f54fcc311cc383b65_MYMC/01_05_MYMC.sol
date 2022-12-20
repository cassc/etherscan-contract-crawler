// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Own Manifold Contract blet
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Rarible to the win    //
//                          //
//                          //
//////////////////////////////


contract MYMC is ERC721Creator {
    constructor() ERC721Creator("My Own Manifold Contract blet", "MYMC") {}
}