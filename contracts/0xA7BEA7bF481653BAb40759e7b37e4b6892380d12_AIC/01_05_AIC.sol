// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Achtung Internet Classic
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//                           @@@@@@@@@@@@@@@                          //
//                        @@@@@@@@@@        @@                        //
//                        @@@@@@@@@@        @@                        //
//                      @@@@@@@@@@@@@@@       @@@                     //
//                      @@@@@@@@@@@@@@@       @@@                     //
//                   @@@@@@@@@@@@@@@@@@@@        @@                   //
//                   @@@@@@@@@@@@@@@@@@@@        @@                   //
//                 @@@@@@@@@@@@@@@@@@@@@@@@@       @@@                //
//                 @@@@@@@@@@@@@@@@@@@@@@@@@       @@@                //
//              @@@@@@@@@@@@@     @@@@@@@@@@@@        @@              //
//              @@@@@@@@@@@@@     @@@@@@@@@@@@        @@              //
//            @@@@@@@@@@@@     @@@  @@@@@@@@@@@@@       @@@           //
//            @@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@       @@@           //
//         @@@@@@@@@@@@@     @@                            @@         //
//         @@@@@@@@@@@@@  @@@                              @@         //
//       @@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@      //
//       @@@@@@@@@@@@                              @@@       @@@      //
//    @@@@@@@@@@@@@                              @@   @@        @@    //
//    @@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@    //
//    @@@@@@@@@@     @@@                      @@@       @@@     @@    //
//       @@@@@@@     @@@                      @@@     @@     @@@      //
//         @@@@@@@@@@                            @@@@@@@@@@@@         //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract AIC is ERC721Creator {
    constructor() ERC721Creator("Achtung Internet Classic", "AIC") {}
}