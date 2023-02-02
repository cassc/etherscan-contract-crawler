// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testaccount0.1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract TTT is ERC721Creator {
    constructor() ERC721Creator("testaccount0.1", "TTT") {}
}