// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: hazed_curated
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//    __  __  ___  ____  _____ _____     //
//    ||==|| ||=||   //  ||==  ||  )     //
//    ||  || || ||  //__ ||___ ||_//     //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract curated is ERC721Creator {
    constructor() ERC721Creator("hazed_curated", "curated") {}
}