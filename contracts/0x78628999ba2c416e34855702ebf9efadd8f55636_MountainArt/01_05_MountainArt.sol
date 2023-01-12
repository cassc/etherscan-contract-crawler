// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Himalayan Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    Native Artist from Himalayan region of Asia.    //
//    Culturally reach Art producer.                  //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract MountainArt is ERC721Creator {
    constructor() ERC721Creator("Himalayan Art", "MountainArt") {}
}