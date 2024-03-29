// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 𝐄𝐝𝐢𝐭𝐢𝐨𝐧𝐬 𝐛𝐲 𝐍𝐎𝐄𝐀𝐒𝐘
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//    ▄▀▀▄ ▀▄  ▄▀▀▀▀▄   ▄▀▀█▄▄▄▄  ▄▀▀█▄   ▄▀▀▀▀▄  ▄▀▀▄ ▀▀▄      //
//    █  █ █ █ █      █ ▐  ▄▀   ▐ ▐ ▄▀ ▀▄ █ █   ▐ █   ▀▄ ▄▀     //
//    ▐  █  ▀█ █      █   █▄▄▄▄▄    █▄▄▄█    ▀▄   ▐     █       //
//      █   █  ▀▄    ▄▀   █    ▌   ▄▀   █ ▀▄   █        █       //
//    ▄▀   █     ▀▀▀▀    ▄▀▄▄▄▄   █   ▄▀   █▀▀▀       ▄▀        //
//    █    ▐             █    ▐   ▐   ▐    ▐          █         //
//    ▐                  ▐                            ▐         //
//                                                              //
//    noeasyvision.eth                                          //
//    lynkfire.com/noeasyvision                                 //
//                                                              //
//    𝐵𝑜𝓇𝓃 𝒾𝓃 𝒱𝑜𝒾𝒹                                    //
//    ⠄⠄⠄⠄⠄⠄⠄⠄⠄⢀⣀⣤⣤⣶⣶⣶⣶⣤⣤⣀⡀                                     //
//    ⠄⠄⠄⠄⠄⠄⣠⣴⣿⠿⠛⠋⣉⣴⣾⣿⣿⣿⣿⣿⣿⣿⣦⣄                                  //
//    ⠄⠄⠄⠄⣠⣾⡿⠋⠄⠄⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄                                //
//    ⠄⠄⢀⣾⡿⠋⠄⠄⠄⠄⣿⣿⣿⠟⠛⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀                              //
//    ⠄⢠⣿⡟⠄⠄⠄⠄⠄⢸⣿⣿⣏⠄⠄⠄⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄                             //
//    ⠄⣾⡿⠄⠄⠄⠄⠄⠄⠈⣿⣿⣿⣶⣤⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷                             //
//    ⢸⣿⠃⠄⠄⠄⠄⠄⠄⠄⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇                            //
//    ⢸⣿⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠛⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇                            //
//    ⢸⣿⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠈⠉⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇                            //
//    ⠸⣿⡄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠻⣿⣿⣿⣿⣿⣿⣿⣿⠇                            //
//    ⠄⢿⣷⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢀⣀⣀⠄⠄⠄⠄⠄⢹⣿⣿⣿⣿⣿⣿⡿                             //
//    ⠄⠘⣿⣧⠄⠄⠄⠄⠄⠄⠄⠄⠄⣿⣿⣿⡇⠄⠄⠄⠄⢸⣿⣿⣿⣿⣿⣿⠃                             //
//    ⠄⠄⠈⢿⣷⣄⠄⠄⠄⠄⠄⠄⠄⠙⠛⠛⠁⠄⠄⠄⠄⣸⣿⣿⣿⣿⡿⠁                              //
//    ⠄⠄⠄⠄⠙⢿⣷⣄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⣰⣿⣿⣿⡿⠋                                //
//    ⠄⠄⠄⠄⠄⠄⠙⠻⣿⣶⣤⣄⣀⣀⣀⣀⣠⣤⣶⣿⣿⣿⠟⠋                                  //
//    ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠈⠉⠛⠛⠿⠿⠿⠿⠛⠛⠉⠁                                     //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract EDBYN is ERC1155Creator {
    constructor() ERC1155Creator(unicode"𝐄𝐝𝐢𝐭𝐢𝐨𝐧𝐬 𝐛𝐲 𝐍𝐎𝐄𝐀𝐒𝐘", "EDBYN") {}
}