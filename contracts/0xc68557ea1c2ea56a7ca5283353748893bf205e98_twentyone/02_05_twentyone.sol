// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 21
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    21    //
//          //
//          //
//////////////


contract twentyone is ERC721Creator {
    constructor() ERC721Creator("21", "twentyone") {}
}