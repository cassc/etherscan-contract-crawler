// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LucaOnAdventure's Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//        LLLLLLLLLLL                                             AAA                   //
//        L ° ° ° ° L                                            A ° A                  //
//         L ° ° ° L                                            A ° ° A                 //
//         L ° ° ° L                                           A ° ° ° A                //
//         L ° ° ° L                                          A °° A °° A               //
//         L ° ° ° L                                         A °° A A °° A              //
//         L ° ° ° L                                        A ° ° ° ° ° ° A             //
//         L ° ° ° L      LLLLLLL                          A °° AAAAAAA °° A            //
//         L ° ° ° LLLLLLLL ° ° L                         A °° A       A °° A           //
//        L ° ° ° ° ° ° ° ° ° ° L                        A °° A         A °° A          //
//        LLLLLLLLLLLLLLLLLLLLLLL                       AAAAAA           AAAAAA         //
//                               O O O O O O O O O O O O                                //
//                               O ° ° ° ° ° ° ° ° ° ° O                                //
//                               O ° ° ° ° ° ° ° ° ° ° O                                //
//                               O ° ° ° O O O O ° ° ° O                                //
//                               O ° ° ° O     O ° ° ° O                                //
//                               O ° ° ° O     O ° ° ° O                                //
//                               O ° ° ° O     O ° ° ° O                                //
//                               O ° ° ° O O O O ° ° ° O                                //
//                               O ° ° ° ° ° ° ° ° ° ° O                                //
//                               O ° ° ° ° ° ° ° ° ° ° O                                //
//                               O O O O O O O O O O O O                                //
//        LLLLLLLLLLLLLLLLLLLLLLL                       AAAAAA           AAAAAA         //
//        L ° ° ° ° ° ° ° ° ° ° L                        A °° A         A °° A          //
//         L ° ° ° LLLLLLLL ° ° L                         A °° A       A °° A           //
//         L ° ° ° L      LLLLLLL                          A °° AAAAAAA °° A            //
//         L ° ° ° L                                        A ° ° ° ° ° ° A             //
//         L ° ° ° L                                         A °° A A °° A              //
//         L ° ° ° L                                          A °° A °° A               //
//         L ° ° ° L                                           A ° ° ° A                //
//         L ° ° ° L                                            A ° ° A                 //
//        L ° ° ° ° L                                            A ° A                  //
//        LLLLLLLLLLL                                             AAA                   //
//                                                                                      //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract LOAed is ERC1155Creator {
    constructor() ERC1155Creator("LucaOnAdventure's Editions", "LOAed") {}
}