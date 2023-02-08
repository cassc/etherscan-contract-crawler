// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Add Your Caption
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract AYC is ERC721Creator {
    constructor() ERC721Creator("Add Your Caption", "AYC") {}
}