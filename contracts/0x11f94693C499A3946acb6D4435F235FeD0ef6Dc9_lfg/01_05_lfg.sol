// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//    reator contract. ASCII art is used to visually identify your contract, and plus it just looks really cool. Take the time to pic    //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract lfg is ERC721Creator {
    constructor() ERC721Creator("2", "lfg") {}
}