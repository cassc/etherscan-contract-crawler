// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NinjaFiendz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Ninja.           //
//    Ninja.           //
//    We are ninja.    //
//                     //
//                     //
/////////////////////////


contract NFSquad is ERC721Creator {
    constructor() ERC721Creator("NinjaFiendz", "NFSquad") {}
}