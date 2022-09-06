// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: It_Was_All_A_Dream
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//       ooooooooooo                              ooooooooooo       //
//     oo:::::::::::oo                          oo:::::::::::oo     //
//    o:::::::::::::::o                        o:::::::::::::::o    //
//    o:::::ooooo:::::o                        o:::::ooooo:::::o    //
//    o::::o     o::::o                        o::::o     o::::o    //
//    o::::o     o::::o                        o::::o     o::::o    //
//    o::::o     o::::o                        o::::o     o::::o    //
//    o::::o     o::::o                        o::::o     o::::o    //
//    o:::::ooooo:::::o                        o:::::ooooo:::::o    //
//    o:::::::::::::::o                        o:::::::::::::::o    //
//     oo:::::::::::oo                          oo:::::::::::oo     //
//       ooooooooooo                              ooooooooooo       //
//                                                                  //
//                      ::::::::::::::::::::::                      //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract no1 is ERC721Creator {
    constructor() ERC721Creator("It_Was_All_A_Dream", "no1") {}
}