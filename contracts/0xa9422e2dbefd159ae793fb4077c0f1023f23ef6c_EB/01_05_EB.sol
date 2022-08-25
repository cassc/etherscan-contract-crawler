// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eleonora Brizi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//    I am a crypto art curator and I also want my (hi)story to be on-chain.     //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract EB is ERC721Creator {
    constructor() ERC721Creator("Eleonora Brizi", "EB") {}
}