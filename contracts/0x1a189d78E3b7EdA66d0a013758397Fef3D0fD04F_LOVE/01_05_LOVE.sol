// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Charitable Open Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                           OOOOO          OOOOO                             //
//                           OO   OOO      OOO   OO                           //
//                           OO     OOO  OOO     OO                           //
//                            OOO     OOOO     OOO                            //
//          OOOOOO          OO  OOOOOO    OOOOOO  OO          OOOOOO          //
//       OOOO    OOOOO   OOOO                      OOOO   OOOOO    OOOO       //
//                   OOOOO     VVVVVV      VVVVVV     OOOOO                   //
//                           VVVVVVVVVV  VVVVVVVVVV                           //
//                         VVVVVVVVVVVVVVVVVVVVVVVVVV                         //
//                         VVVVVVVVVVVVVVVVVVVVVVVVVV                         //
//            XXXXXX       VVVVVVVVVVVVVVVVVVVVVVVVVV      XXXXXXX            //
//         XXXXXXXXXXX      VVVVVVVVVVVVVVVVVVVVVVVV      XXXXXXXXXXX         //
//        XXXXXXXXXXXXX      VVVVVVVVVVVVVVVVVVVVVV      XXXXXXXXXXXXX        //
//       XXXXXXXXXXXXXXXX     VVVVVVVVVVVVVVVVVVVV     XXXXXXXXXXXXXXXX       //
//       XXXXXXXXXXXXXXXX      VVVVVVVVVVVVVVVVVV      XXXXXXXXXXXXXXXX       //
//       XXXXXXXXXXXXXXXX     XXVVVVVVVVVVVVVVVVXX     XXXXXXXXXXXXXXXX       //
//        XXXXXXXXXXXXXXXX    XXXVVVVVVVVVVVVVVXXX    XXXXXXXXXXXXXXXX        //
//           XXXXXXXXXXX     XXXX VVVVVVVVVVVV XXXX     XXXXXXXXXXX           //
//               XXXXXXX    XXXX   VVVVVVVVVV   XXXX    XXXXXXX               //
//        XXXXXX  XXXXXXXXXXXXXX    VVVVVVVV    XXXXXXXXXXXXXX  XXXXXX        //
//      XXXXXXXXXXXXXXXXXXXXXX       VVVVVV       XXXXXXXXXXXXXXXXXXXXXX      //
//     XXXXXXXXXXXXXXXXXXXX           VVVV           XXXXXXXXXXXXXXXXXXXX     //
//    XX XXXXX XXXXXXXXXXXX            VV            XXXXXXXXXXXX XXXXX XX    //
//    X  X XX  XXXXXXXXXXXX                          XXXXXXXXXXXX  XX X  X    //
//         X  XXXXXXXXXXXX                            XXXXXXXXXXXX  X         //
//           XXXXXXXXXXXXX                            XXXXXXXXXXXXX           //
//           XXXXXXXXXXXXXX                          XXXXXXXXXXXXXX           //
//           XXXXXXXXXXXXXXX                        XXXXXXXXXXXXXXX           //
//            XXXXXXXXXXXXXXX                      XXXXXXXXXXXXXXX            //
//           XXXXXXX  XXXXXXXX                    XXXXXXXX  XXXXXXX           //
//          XXXXXXX     XXXXXXX                  XXXXXXX     XXXXXXX          //
//     XXXXXXXXXXX        XXXXXX                XXXXXX        XXXXXXXXXXX     //
//     XXXXXXXXX           XXXXX                XXXXX           XXXXXXXXX     //
//     XXXX                 XXXXX              XXXXX                 XXXX     //
//      XXX                  XXXXX            XXXXX                  XXX      //
//                            XXXX            XXXX                            //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract LOVE is ERC1155Creator {
    constructor() ERC1155Creator("Charitable Open Editions", "LOVE") {}
}