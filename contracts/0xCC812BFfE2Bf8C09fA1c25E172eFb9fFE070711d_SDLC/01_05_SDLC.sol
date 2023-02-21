// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Storytime DAO Library Card
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    The story of now    //
//                        //
//                        //
////////////////////////////


contract SDLC is ERC1155Creator {
    constructor() ERC1155Creator("Storytime DAO Library Card", "SDLC") {}
}