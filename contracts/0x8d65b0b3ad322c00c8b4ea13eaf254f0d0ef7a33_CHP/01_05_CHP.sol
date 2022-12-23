// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: christophrp
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    +-++-++-++-++-++-++-++-++-++-++-+     //
//    |c||h||r||i||s||t||o||p||h||r||p|     //
//    +-++-++-++-++-++-++-++-++-++-++-+     //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract CHP is ERC721Creator {
    constructor() ERC721Creator("christophrp", "CHP") {}
}