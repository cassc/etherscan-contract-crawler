// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pussy Riot / Physical Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//     _____                    _____ _     _       //
//    |  _  |_ _ ___ ___ _ _   | __  |_|___| |_     //
//    |   __| | |_ -|_ -| | |  |    -| | . |  _|    //
//    |__|  |___|___|___|_  |  |__|__|_|___|_|      //
//                      |___|                       //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract RIOT is ERC721Creator {
    constructor() ERC721Creator("Pussy Riot / Physical Art", "RIOT") {}
}