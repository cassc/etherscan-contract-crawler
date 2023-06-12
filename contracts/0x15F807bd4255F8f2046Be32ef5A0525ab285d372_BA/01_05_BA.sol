// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Black Avenger
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    ( ;∀;)    //
//              //
//              //
//////////////////


contract BA is ERC721Creator {
    constructor() ERC721Creator("Black Avenger", "BA") {}
}