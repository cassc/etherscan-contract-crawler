// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cut flowers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Mia Forrest    //
//                   //
//                   //
///////////////////////


contract ctflwrs is ERC721Creator {
    constructor() ERC721Creator("cut flowers", "ctflwrs") {}
}