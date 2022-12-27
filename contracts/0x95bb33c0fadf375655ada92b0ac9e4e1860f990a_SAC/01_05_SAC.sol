// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Smokin Alien
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Samih Free Christmas NFT    //
//                                //
//                                //
////////////////////////////////////


contract SAC is ERC721Creator {
    constructor() ERC721Creator("Smokin Alien", "SAC") {}
}