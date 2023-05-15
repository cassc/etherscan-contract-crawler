// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Midnight Labs burn
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    ⠀⠀⠀⠀⠀⠀⢱⣆⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠈⣿⣷⡀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⢸⣿⣿⣷⣧⠀⠀⠀    //
//    ⠀⠀⠀⠀⡀⢠⣿⡟⣿⣿⣿⡇⠀⠀    //
//    ⠀⠀⠀⠀⣳⣼⣿⡏⢸⣿⣿⣿⢀⠀    //
//    ⠀⠀⠀⣰⣿⣿⡿⠁⢸⣿⣿⡟⣼⡆    //
//    ⢰⢀⣾⣿⣿⠟⠀⠀⣾⢿⣿⣿⣿⣿    //
//    ⢸⣿⣿⣿⡏⠀⠀⠀⠃⠸⣿⣿⣿⡿    //
//    ⢳⣿⣿⣿⠀⠀⠀⠀⠀⠀⢹⣿⡿⡁    //
//    ⠀⠹⣿⣿⡄⠀⠀⠀⠀⠀⢠⣿⡞⠁    //
//    ⠀⠀⠈⠛⢿⣄⠀⠀⠀⣠⠞⠋⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀⠀    //
//                      //
//                      //
//////////////////////////


contract midb is ERC721Creator {
    constructor() ERC721Creator("Midnight Labs burn", "midb") {}
}