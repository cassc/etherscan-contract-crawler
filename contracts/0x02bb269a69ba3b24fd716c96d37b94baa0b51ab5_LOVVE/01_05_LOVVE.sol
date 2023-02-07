// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LoVVe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//                               .XXX                                             //
//                       XXXXX     XXX  X.                                        //
//                   XXXXXXXXXXXXXXXXXXXXX X.                                     //
//                 .XXXXXXXXXXXXXXXXXXXXXX XX                                     //
//              .XXXXXXXXXXXXXXXXXXXXXXXXXXXX                                     //
//             XXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                      //
//            XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.                                     //
//            XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX              ...                    //
//         XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX            XXXXXXX    .XXXX.        //
//         XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX           XXXXXXXXX .XXXXXXXXX      //
//          XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.          .XXXXXXXXXXXXXXXXXXXXX     //
//         .XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.      XXXXXXXXXXXXXXXXXXXXXX.    //
//         XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX       XXXXXXXXXXXXXXXXXXXXXX.    //
//          XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.      .XXXXXXXXXXXXXXXXXXXXX     //
//          XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     XXXXXXXXXXXXXXXXXXXXXX      //
//         X.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX     .XXXXXXXXXXXXXXXXXXXXX.      //
//         XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.     XXXXXXXXXXXXXXXXXXXXX       //
//            XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.     .XXXXXXXXXXXXXXXXXX.        //
//           XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    XXXXXXXXXXXXXXXXXXX.         //
//             XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    XXXXXXXXX XXXXXXXXX           //
//              XXXXXXXXXXXXXXXXXXXXXXXXXXXX.      XXXXXXXXX.  XXXXXX             //
//                     XXXXXXX..XXXXXXXXXXX     .XXXXXXXXXXX    .XX               //
//                              .XXXXXXXXX  ..XXXXXXXXXXXXX      .                //
//                     .XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                        //
//                   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.     .                   //
//                 .XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.       X                   //
//               XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.         XX                   //
//              .XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.         .XXX                   //
//              XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX       .XXXXX.                  //
//                   XXXXX XXXXXXXXXXXXXXXXXXXXXXXX    .XXXXXXXX                  //
//                      .  ..  XXXXXXXXXXXXXXXXXXX        XXXXXXX                 //
//                             XXXXXXXXXXXXXXXXXXX        XXX    .                //
//                             XXXXXXXXXXXXXXXXXX.   .XXXXXXX                     //
//                          X  XXXXXXXXXXXXXXXXXX   XXXXXXXXXX                    //
//                         XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                    //
//                       .XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                     //
//                      .XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                     //
//                     .XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                     //
//                     .XXXXXXXXXXXXXXXXXXXXXX       XXXXX.                       //
//                     .XXXXXXXXXXXXXXXXXXXXX       .XXXXXX                       //
//                     .XXXXXXXXXXXXXXXXXXXXX      .XXXXXX.                       //
//                       XXXXXXXXXXXXXXXXXXXXX.    XXXXXXX                        //
//                        XXXXXXXXXXXXXXXXXXXXXX   .X. XX                         //
//                       XXXXXXXXXXXXXXXXXXXXXXXXX      X                         //
//                      XXXXXXXXXXXXXXXXXXXXXXXXXXXX    .                         //
//                     .XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                            //
//                     XXXXXXXXXXXXX .XXXXXXXXXXXXXXXX.                           //
//                ..XXXXXXXXXXXXXXX      .XXXXXXXXXXXXX                           //
//              .XXXXXXXXXXXXXXXXX.         .XXXXXXXXXX                           //
//            .XXXXXXXXXXXXXXXXXXX           XXXXXXXXXX                           //
//        .XXXXXXXXXXXXXXXXXXXXX             XXXXXXXXXX                           //
//       .XXXXXXXXXXXXXXXXXXXXXX             XXXXXXXXXX                           //
//       .XXXXXXXXXXXXXXXXXX.                .XXXXXXXXXX                          //
//        XXXXXXXXXX..     X.                .XXXXXXXXXX.                         //
//        .XXXXXXXX                             XXXXXXXXX.                        //
//        XXXXXXXXX                              XXXXXXXX.                        //
//       .XXXXXXXX                                XXXXXXXXX.                      //
//        XXXXXXXX                               XXXXXXXXXXX                      //
//          XXXXXX                                XXXXXXXXXX                      //
//              .                                  .XXXXXXXXX                     //
//                                                   .XXXXXXXX                    //
//                                                     XXXXXXX.                   //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract LOVVE is ERC1155Creator {
    constructor() ERC1155Creator("LoVVe", "LOVVE") {}
}