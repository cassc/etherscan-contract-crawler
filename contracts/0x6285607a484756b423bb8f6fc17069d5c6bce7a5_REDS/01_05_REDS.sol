// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Red Sails
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//    ██████╗ ███████╗██████╗     ███████╗ █████╗ ██╗██╗     ███████╗        //
//    ██╔══██╗██╔════╝██╔══██╗    ██╔════╝██╔══██╗██║██║     ██╔════╝        //
//    ██████╔╝█████╗  ██║  ██║    ███████╗███████║██║██║     ███████╗        //
//    ██╔══██╗██╔══╝  ██║  ██║    ╚════██║██╔══██║██║██║     ╚════██║        //
//    ██║  ██║███████╗██████╔╝    ███████║██║  ██║██║███████╗███████║        //
//                                                                           //
//                                                                           //
//                                                                           //
//                                      |                                    //
//                                     d b                                   //
//                                    d8 bb                                  //
//                                   dP8 8bb                                 //
//                                  d888 8bbb                                //
//                                 d8P88 888bb                               //
//                                d88888 8bbbbb                              //
//                               d88P888 8bbbbbb                             //
//                              d8888888 8bbbbbbb                            //
//                             d888P8888 8bbbb8b8b                           //
//                            d8888b8bb8 8b8b8b8bbb                          //
//                           d8888P8b888 88b8b8b8b8b                         //
//                          d88888b8b8b8 8b8b8bbb8bbb                        //
//                         d88888booooo8 8bbb8b8b8b8bb                       //
//               Y8000rightclicksaveasgmgmgmgmgmmmanifoldmmmgaY              //
//                YcgngnngmgmmggnfndogmgmgmgmgmgmgmgmgmggcgmmY               //
//                 YuyseizethememesofproductiongmgmgmgmgmgmgY                //
//                  YoooooooooooocopeooooooooooooooooooommyY                 //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract REDS is ERC721Creator {
    constructor() ERC721Creator("Red Sails", "REDS") {}
}