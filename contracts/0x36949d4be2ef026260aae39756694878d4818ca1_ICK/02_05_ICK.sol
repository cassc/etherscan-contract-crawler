// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ICKI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠤⠒⠒⠒⠒⠒⠢⢤⣀⠀⠀⠀⠀⢀⣠⠤⠤⠤⠤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀     //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠖⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠑⢦⡔⠊⠁⠀⠀⠀⠀⠀⠀⠈⠓⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡞⠁⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⣀⠀⠀⠱⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢣⠀⠀⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠏⠀⠀⠀⢀⡤⠖⠉⠁⠀⠀⠀⠀⠀⠀⠉⠒⢤⣧⠤⠤⠤⠶⠒⠒⠒⠒⠲⠦⠬⠦⣀⡀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⡤⠤⠤⢽⣦⣄⠀⠀⠀⠀⣀⣀⣤⡤⠤⣤⣤⣉⣢⡀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⢀⡼⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠴⠒⠋⣉⣀⡤⠤⠴⠶⠦⠤⢌⣱⣴⣚⡭⠥⠖⠒⠒⠒⠚⠒⠒⠮⢍⣳⡀⠀    //
//    ⠀⠀⠀⠀⠀⢀⡴⠋⢩⠇⠀⠀⠀⠀⠀⣀⣶⡾⠯⠖⠒⠉⠉⠀⠀⢀⣀⣀⡤⠤⠶⠶⠿⢏⠀⣀⡠⠤⠖⠒⣒⣯⣯⣉⠓⠒⠬⣿⡄    //
//    ⠀⠀⠀⠀⠀⡜⠀⠀⢸⠆⠀⠀⠀⠀⠀⠻⣄⣀⣀⠤⠤⠤⠔⠒⣺⣿⢛⣿⣿⣷⣄⠀⠀⣸⠉⠀⠀⠀⣠⣾⣯⣿⡿⢿⣷⡄⠀⢈⡇    //
//    ⠀⠀⠀⠀⡼⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣎⠓⠤⣀⠀⢰⣿⣿⣿⣿⣀⣽⣿⣦⠔⡧⣄⣀⡀⢀⣿⣿⣿⣿⣦⡾⠿⠧⣶⠏⠀    //
//    ⠀⠀⠀⡼⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠒⠒⠿⠿⢿⣭⣯⣭⣩⣭⡤⠤⠚⠁⠀⠀⠉⠉⠀⠀⠀⠀⠀⠀⣠⠞⠁⠀⠀    //
//    ⠀⠀⡰⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠤⠞⠁⠀⠀⠀⠢⢄⣀⣀⣀⣀⣀⡠⣤⠚⠁⠀⠀⠀⠀    //
//    ⠀⡰⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠴⠒⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⠁⠀⠀⠀⠈⠳⡀⠀⠀⠀⠀    //
//    ⢰⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⡀⠀⠀⠀    //
//    ⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣧⠀⠀⠀    //
//    ⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠉⠉⠈⠉⠉⠉⠉⠓⠒⠦⠤⢄⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣠⠤⠖⠊⠉⡇⠀⠀    //
//    ⠸⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣏⠀⠐⠒⠋⠉⠉⠛⠒⠒⠦⠤⢤⣀⣀⣈⠉⠉⠉⠉⠉⠉⠉⠉⠉⢀⣀⣀⣀⣠⠞⠀      //
//    ⠀⠹⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡆⠀⠙⠗⠒⠶⠤⠤⠤⣄⣀⣀⡀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠁⠀⠀⡞⠀⠀⠀⠀    //
//    ⠀⠀⠈⠦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠲⠤⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠙⠒⠒⠒⠒⠒⠲⠦⠶⠒⠶⣶⠦⠒⠊⠁⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠈⠓⠦⢄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠴⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠓⠒⠠⠤⠤⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⠤⠴⠒⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract ICK is ERC721Creator {
    constructor() ERC721Creator("ICKI", "ICK") {}
}