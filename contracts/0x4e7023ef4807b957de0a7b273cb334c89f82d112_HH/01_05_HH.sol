// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Heaven And Hell
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣼⣿⣶⣤⣄⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⡦⣤⣶⠒⠚⢻⠶⣦⣴⡒⠚⠺⠓⡲⣶⡶⠚⠛⠉⠀⠀⠈⠁⠘⠳⣬⣩⡝⠛⠳⡄⠀⠀⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⠓⢿⣤⠟⠉⠁⠀⠀⣀⣀⡀⠉⠉⠑⢶⠾⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⠟⠳⠚⣹⣶⠈⢳⡆⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⢀⣘⡷⠏⠁⠀⣠⡴⠞⠋⠉⠉⠉⠀⠀⠐⠶⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⣤⣴⣿⣷⣾⣿⣶⡄    //
//    ⠀⠀⠀⠀⠀⢀⣀⣼⠋⠉⠀⠀⠠⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣤⣴⣶⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⠛⠉⢹⣿⡇    //
//    ⠀⠀⠀⠀⢀⣼⡿⠁⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣤⣤⣤⣶⣶⣿⣿⣿⡿⣿⣿⡿⠛⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠷⣦⣴⡿⠀    //
//    ⠀⠀⠀⣾⣋⣀⣁⣀⣤⣤⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⢸⠿⠧⣀⣀⡿⠛⢻⣿⣿⣿⣿⣿⣿⣿⣇⣀⣀⣿⡿⠀⠀    //
//    ⢀⣤⣾⣿⡿⠿⠿⠿⠛⠛⠋⠉⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣏⠉⠉⣿⣇⠀⢀⣻⡿⠃⠀⠈⠛⠛⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀    //
//    ⣿⣧⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⢹⣿⣿⣿⣿⣿⣿⣿⣿⣤⣴⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠉⠉⠁⠀⢀⣠⣽⣿⡇⠀⠀⠀    //
//    ⣿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠈⣿⣿⣿⣿⣿⣛⠛⠛⠿⠿⣥⣤⣤⣀⣀⣀⣀⣀⣀⣤⣤⡴⠞⠛⠙⣻⣿⠁⠀⠀⠀    //
//    ⢿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣌⠛⢿⣿⣻⣷⣶⣤⣤⣤⣭⣭⣿⣭⣭⡿⠿⠿⢿⡞⠋⠹⣾⣇⣿⣶⡆⡀⠀    //
//    ⣾⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢦⣉⠛⢿⣍⡉⠛⠿⣿⣭⣉⣉⣽⡷⠀⠀⠀⢙⡆⢸⡿⠻⣿⡋⣿⠃⠀    //
//    ⢸⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⢶⣤⣉⠛⠳⠾⠿⠿⠿⢧⣤⠶⠾⠋⣩⣷⢿⣼⡟⠁⠉⠉⠀⠀    //
//    ⠉⠙⠿⣦⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠛⠿⢿⣷⣾⣿⣿⣿⣿⣿⣿⠁⠈⠉⠳⡄⠀⠀⠀⠀    //
//    ⠀⠀⠀⠀⠉⠛⠿⠷⣶⣦⣤⣤⣀⣀⣀⣀⣀⣠⣤⣤⣤⣤⣤⣤⣶⣶⣶⣶⣶⣶⣶⡶⠿⠿⠿⠿⠛⠛⠋⠀⠀⠀⠀⠀⠈⢣⣀⠀⠀    //
//    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢮⡹⡆⠀    //
//    ⠀⠀⠀⡀⢀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⡇⠀    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract HH is ERC1155Creator {
    constructor() ERC1155Creator("Heaven And Hell", "HH") {}
}