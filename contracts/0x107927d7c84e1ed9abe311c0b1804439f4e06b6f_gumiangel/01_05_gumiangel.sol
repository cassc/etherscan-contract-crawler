// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gumi's angels
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    <3    //
//          //
//          //
//////////////


contract gumiangel is ERC721Creator {
    constructor() ERC721Creator("gumi's angels", "gumiangel") {}
}