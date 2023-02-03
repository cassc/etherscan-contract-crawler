// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nerd DAO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//                     ,,,                        Tee hee!                 //
//                     '..             OO                `~^^              //
//                      ||            ((                   >>              //
//                 ____ |\ ___________ bb ________________ |\ _______      //
//                                                                         //
//                                                                         //
//           Another experiment          Yeah. And as always, Mandy was    //
//             gone bad?   `,,,          ,   there to add insult to        //
//                          '..        OO    injury. I -hate- that!        //
//                          .||.      -||-                                 //
//                      ____ || ______ dd ________________                 //
//                                                                         //
//                                                                         //
//     If it bothers you that                                              //
//     much, talk to her.  `,,,                                            //
//      Explain how you     '..        OO                                  //
//       feel and all.      .||.      .||.                                 //
//                      ____ || ______ dd ____                             //
//                                                                         //
//                          ,,,                                            //
//                          '..        OO                                  //
//                          .||.      .||.                                 //
//                      ____ || ______ dd ____                             //
//                                                                         //
//                                                                         //
//                                       OK you lost me.                   //
//                          ,,,          ,                                 //
//                          '..        OO                                  //
//                          .||.       ||                                  //
//         jg_______________ || ______ dd __________________               //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract NERD is ERC721Creator {
    constructor() ERC721Creator("Nerd DAO", "NERD") {}
}