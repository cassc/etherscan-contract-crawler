// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ABalastegui
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//                                                                              //
//                                                          ▒                   //
//                                    ▐▒   ▒                ░                   //
//                                     ░▒░▒                 ░                   //
//                                     ░░▒                  ░    ▒▒             //
//                               ▒     ░▒                   ░▒ ▒░               //
//                               ▐▒   ▐░                   ▒░░▒▀                //
//                                ░   ▐░           ▄      ▒░                    //
//                           ▒▒  ▐░▒  ▐░  ▓▓  ▐▄  ▄▓▓  ▄  ░░▄                   //
//                             ▒▒░░░▒ ▐░  ▓▓▓▄▀▓▌▐▓▓▓▌▓▓ ▄░░▓      ▒   ▒        //
//                                ▐▓▓░░░░▌▓▓▓▓ ▄ ▓▓▓▓▒ ▀▓▓░░▓▐▓▌  ▒▒▒           //
//                                 ▓▓▓▓░░▒▀▓▀▌▓▒▓  ▀▐▒▓▐▀░░░▄▐▀ ▒▄▓▓            //
//                              ▓▓▓▄▓▓▓▌░░░▒░░▀▌▌▒░ ▓▓ ▒░░░▓▌▒░▄▓▓▓ ▄▄          //
//                           ▓▓▓▓▓ ▄▄▓ ░░▒░░░░░  ░░░  ▒░▒▒░░▒▒▀▀▀▓ ▓▓           //
//                            ▀▓▓▓▓▄▓▒▓ ░░░▒░░▄▄▄   ▄▄▄░▒░░ ░ ▓▒▌ ▄▓▓▓▓▓▓▀      //
//                         ▀▓▓▓▄▀▀  ░░░▀ ▒░ ▓▀▀▒▒▒▒▒▒▀▀▓▀ ░░ ▀░░░ ▓▓▓▓▓▀        //
//                       ▄▄▄▀▓▄▒▓▒▒▄░▒░░ ▄ ▒▒░▒░▒░▒▒▒░▒░▒ ▄▄░░░▒▄▄▄▄▄ ▄▓▓▀      //
//                        ▀▓▓▓▓▓▌ ▀░░  ░▓▓▓▓░░░░░░░▒░░░░░▓▀▓▓  ▀▀▀▀▐▄▓▓▄▄▄▄     //
//                        ▄▄▄▓▀▀ ▄░▒░░░▀▓░▄▓▀░▐▓▓▓░▓▓▓░░▀▓░░▓▒░░░▒░ ▓▓▓▓▓▓▀▀    //
//                        ▀▀▓▄▒▀▓▒▓▀  ░ ▐▓▀░░▒▒▀▀▒▒▒▀▒▒▒░░▀▓     ▓▒▒▓▄ ▐▄▄▄     //
//                       ▄▓▓▓▓▓▓▀ ░░░░░▓▓             ░░   ▐▓░░░░░░ ▄▀▄▓▀▀      //
//                        ▀▀▀▀▀▀▒▄▄▄▄  ░▓▌  ▒    ▐▓        ▓▓  ▄▄▄▄▀▓▓▓▓▓▓▄     //
//                         ▄▓▓ ▐▀▀▀▀░░░░░▀▒      ▐▓       ░▀ ░░░▀▓▒▒▄▀▀▀▀▀▀▀    //
//                           ▄▓▓▓▓▄ ░▄▄  ░░░▓▄▄▄     ▄▄▓▓░░  ▄░░░ ▓▓▄▀▓▓▓       //
//                         ▄▓▓▓▓▀▀▀▓▒▌▀ ░░░ ░ ▀▀▀░░▒▀▀ ░ ░░░░▐▒▒▄▀▓▓▓▓▄         //
//                             ▓▓▌▄▄▄▓  ▄▄▓ ░░░▄ ░░░▄░░░ ▓▄▄░ ▄▄▀ ▀▀▓▓▓▓        //
//                             ▀ ▄▓▓▓▓▓ ▒▓▀ ▒ ▐▒ ▒░ ▒▓ ▒ ▓▒▒▐▓▓▓▌▀▓▓            //
//                              ▐▓▓▓▀▄▓ ▄▓▓▓▓▐▒▓▄▄ ▐▒▒ ▓▄▓ ▀ ▓▓▓▓▌              //
//                                   ▓▀ ▓▓▓▓▀▄▀▄▓▓▓▌▄▀▓▓▓▓▌▓▓▓ ▀▓▓              //
//                                     ▐▓▓▀ ▓▓▌▓▓▓▓ ▓▓ ▓▓▓▌  ▀                  //
//                                      ▀       ▓▓▀  ▀  ▀▓▌                     //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract BALAS is ERC721Creator {
    constructor() ERC721Creator("ABalastegui", "BALAS") {}
}