// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UINTS PEPE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    Pepe is art and we are artists    //
//                                      //
//                                      //
//////////////////////////////////////////


contract UP is ERC1155Creator {
    constructor() ERC1155Creator("UINTS PEPE", "UP") {}
}