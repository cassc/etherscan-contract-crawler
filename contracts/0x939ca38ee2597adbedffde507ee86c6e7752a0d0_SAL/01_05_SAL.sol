// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anthony Sal Abstract Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//       SSSSSSSSSSSSSSS              AAA               LLLLLLLLLLL                 //
//     SS:::::::::::::::S            A:::A              L:::::::::L                 //
//    S:::::SSSSSS::::::S           A:::::A             L:::::::::L                 //
//    S:::::S     SSSSSSS          A:::::::A            LL:::::::LL                 //
//    S:::::S                     A:::::::::A             L:::::L                   //
//    S:::::S                    A:::::A:::::A            L:::::L                   //
//     S::::SSSS                A:::::A A:::::A           L:::::L                   //
//      SS::::::SSSSS          A:::::A   A:::::A          L:::::L                   //
//        SSS::::::::SS       A:::::A     A:::::A         L:::::L                   //
//           SSSSSS::::S     A:::::AAAAAAAAA:::::A        L:::::L                   //
//                S:::::S   A:::::::::::::::::::::A       L:::::L                   //
//                S:::::S  A:::::AAAAAAAAAAAAA:::::A      L:::::L         LLLLLL    //
//    SSSSSSS     S:::::S A:::::A             A:::::A   LL:::::::LLLLLLLLL:::::L    //
//    S::::::SSSSSS:::::SA:::::A               A:::::A  L::::::::::::::::::::::L    //
//    S:::::::::::::::SSA:::::A                 A:::::A L::::::::::::::::::::::L    //
//     SSSSSSSSSSSSSSS AAAAAAA                   AAAAAAALLLLLLLLLLLLLLLLLLLLLLLL    //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract SAL is ERC1155Creator {
    constructor() ERC1155Creator("Anthony Sal Abstract Editions", "SAL") {}
}