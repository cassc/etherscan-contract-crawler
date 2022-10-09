// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Empathetic Photography
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Empathetic Photography    //
//                              //
//                              //
//////////////////////////////////


contract EMPic is ERC721Creator {
    constructor() ERC721Creator("Empathetic Photography", "EMPic") {}
}