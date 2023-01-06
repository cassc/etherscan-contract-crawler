// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cajas Misteriosas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Billie Alter -> Luis Angel    //
//                                  //
//                                  //
//////////////////////////////////////


contract CM is ERC721Creator {
    constructor() ERC721Creator("Cajas Misteriosas", "CM") {}
}