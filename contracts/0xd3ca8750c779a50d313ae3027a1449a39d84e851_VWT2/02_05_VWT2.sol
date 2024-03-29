// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARI VW T2
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀              //
//    ⠀⠀⠀⠀⠀⠀⣀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣀⠀⠀⠀⠀⠀⠀              //
//    ⠀⠀⠀⠀⣠⣾⣿⡿⠟⠋⠁⠀⠀⠀⠀⠀⠀⠈⠙⠻⢿⣿⣷⣄⠀⠀⠀⠀              //
//    ⠀⠀⢠⣾⣿⡿⠋⠀⠀⡀⠀⠀⣶⣶⣶⣶⠂⠀⢀⠀⠀⠙⢿⣿⣷⡄⠀⠀              //
//    ⠀⢠⣿⣿⠏⠀⠀⣠⣾⣿⡀⠀⠘⣿⣿⠃⠀⠀⣾⣷⣄⠀⠀⠹⣿⣿⡄⠀              //
//    ⢠⣿⣿⠏⠀⠀⠀⠸⣿⣿⣷⡀⠀⠘⠇⠀⠀⣾⣿⣿⡏⠀⠀⠀⠹⣿⣿⡄              //
//    ⢸⣿⣿⠀⠀⢠⠀⠀⠹⣿⣿⣷⣀⣀⣀⣀⣼⣿⣿⡟⠀⠀⡀⠀⠀⣿⣿⡇              //
//    ⢸⣿⣿⠀⠀⢸⣇⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⣰⡇⠀⠀⣿⣿⡇              //
//    ⢸⣿⣿⠀⠀⢸⣿⣆⠀⠀⢻⠏⠉⠉⡉⠉⠙⡿⠀⠀⢰⣿⡇⠀⠀⣿⣿⡇              //
//    ⠘⣿⣿⣆⠀⠀⢻⣿⣆⠀⠀⠀⠀⣼⣧⠀⠀⠀⠀⢠⣿⡟⠀⠀⣰⣿⣿⠃              //
//    ⠀⠘⣿⣿⣆⠀⠀⠙⢿⡄⠀⠀⣼⣿⣿⣧⠀⠀⢀⡿⠋⠀⠀⣰⣿⣿⠃⠀              //
//    ⠀⠀⠘⢿⣿⣷⣄⠀⠀⠉⠀⠴⠿⠿⠿⠿⠧⠀⠈⠀⠀⣠⣾⣿⡿⠃⠀⠀              //
//    ⠀⠀⠀⠀⠙⢿⣿⣷⣦⣄⡀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣾⣿⡿⠋⠀⠀⠀⠀              //
//    ⠀⠀⠀⠀⠀⠀⠉⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠉⠀⠀⠀⠀⠀⠀              //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀               //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract VWT2 is ERC721Creator {
    constructor() ERC721Creator("ARI VW T2", "VWT2") {}
}