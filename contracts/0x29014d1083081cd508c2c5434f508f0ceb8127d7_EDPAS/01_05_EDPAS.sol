// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ed Pas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//             OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO             //
//         OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO         //
//       OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO       //
//      OOOOOOO                                                             OOOOOOO       //
//      OOOOO                                                                 OOOOO       //
//      OOOO                                                                   OOOO       //
//      OOOO                                OOOOOOOOO                          OOOO       //
//      OOOO                        OOOOOOOOOOOOOOOOOOOOOOOO                   OOOO       //
//      OOOO                   OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO              OOOO       //
//      OOOO                OOOOOOOOOOOO                   OOOOOOOOO           OOOO       //
//      OOOO              OOOOOOOOOO                                           OOOO       //
//      OOOO             OOOOOOOO                 OOOOOOOOOOO                  OOOO       //
//      OOOO            OOOOOO                    OOOOOOOOOOOOOO               OOOO       //
//      OOOO           OOOOOO                     OOOO     OOOOOO              OOOO       //
//      OOOO          OOOOOO                      OOOO       OOOOO             OOOO       //
//      OOOO         OOOOOO                       OOOO        OOOOO            OOOO       //
//      OOOO         OOOOO                        OOOO         OOOO            OOOO       //
//      OOOO         OOOOO                        OOOO         OOOO            OOOO       //
//      OOOO         OOOOOOOOOOOOOOOOOOOOOOOOO    OOOO        OOOO             OOOO       //
//      OOOO         OOOOOOOOOOOOOOOOOOOOOOOOO    OOOO       OOOOO             OOOO       //
//      OOOO         OOOOO                        OOOO     OOOOOO              OOOO       //
//      OOOO         OOOOO                        OOOOOOOOOOOOO                OOOO       //
//      OOOO          OOOOO                       OOOOOOOOOO                   OOOO       //
//      OOOO           OOOOOO                     OOOO                         OOOO       //
//      OOOO            OOOOOO                    OOOO                         OOOO       //
//      OOOO             OOOOOOO                  OOOO                         OOOO       //
//      OOOO               OOOOOOOOO                           OOOOO           OOOO       //
//      OOOO                 OOOOOOOOOOOOOOO             OOOOOOOOOO            OOOO       //
//      OOOO                    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO              OOOO       //
//      OOOO                        OOOOOOOOOOOOOOOOOOOOOOOOO                  OOOO       //
//      OOOOOO                               OOOOOOOO                          OOOO       //
//       OOOOO                                                                 OOOO       //
//       OOOOO                                                                OOOOO       //
//       OOOOOO                                                              OOOOOO       //
//        OOOOOOOOOO                                               OOOOOOOOOOOOOOOO       //
//         OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO        //
//           OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO           //
//                OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO                     //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract EDPAS is ERC721Creator {
    constructor() ERC721Creator("Ed Pas", "EDPAS") {}
}