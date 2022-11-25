// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Soulmate
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    astronaut teacher | co-creator, Cosmic Paws    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract CODJ is ERC721Creator {
    constructor() ERC721Creator("Soulmate", "CODJ") {}
}