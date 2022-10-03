// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test TC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract TEST is ERC721Creator {
    constructor() ERC721Creator("Test TC", "TEST") {}
}