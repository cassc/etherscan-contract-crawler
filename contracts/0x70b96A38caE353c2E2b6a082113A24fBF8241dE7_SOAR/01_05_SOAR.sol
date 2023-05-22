// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Perspective
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//            CCCCCCCCCCCCC               AAA               LLLLLLLLLLL                 //
//         CCC::::::::::::C              A:::A              L:::::::::L                 //
//       CC:::::::::::::::C             A:::::A             L:::::::::L                 //
//      C:::::CCCCCCCC::::C            A:::::::A            LL:::::::LL                 //
//     C:::::C       CCCCCC           A:::::::::A             L:::::L                   //
//    C:::::C                        A:::::A:::::A            L:::::L                   //
//    C:::::C                       A:::::A A:::::A           L:::::L                   //
//    C:::::C                      A:::::A   A:::::A          L:::::L                   //
//    C:::::C                     A:::::A     A:::::A         L:::::L                   //
//    C:::::C                    A:::::AAAAAAAAA:::::A        L:::::L                   //
//    C:::::C                   A:::::::::::::::::::::A       L:::::L                   //
//     C:::::C       CCCCCC    A:::::AAAAAAAAAAAAA:::::A      L:::::L         LLLLLL    //
//      C:::::CCCCCCCC::::C   A:::::A             A:::::A   LL:::::::LLLLLLLLL:::::L    //
//       CC:::::::::::::::C  A:::::A               A:::::A  L::::::::::::::::::::::L    //
//         CCC::::::::::::C A:::::A                 A:::::A L::::::::::::::::::::::L    //
//            CCCCCCCCCCCCCAAAAAAA                   AAAAAAALLLLLLLLLLLLLLLLLLLLLLLL    //
//            CCCCCCCCCCCCCAAAAAAA                   AAAAAAALLLLLLLLLLLLLLLLLLLLLLLL    //
//         CCC::::::::::::C A:::::A                 A:::::A L::::::::::::::::::::::L    //
//       CC:::::::::::::::C  A:::::A               A:::::A  L::::::::::::::::::::::L    //
//      C:::::CCCCCCCC::::C   A:::::A             A:::::A   LL:::::::LLLLLLLLL:::::L    //
//     C:::::C       CCCCCC    A:::::AAAAAAAAAAAAA:::::A      L:::::L         LLLLLL    //
//    C:::::C                   A:::::::::::::::::::::A       L:::::L                   //
//    C:::::C                    A:::::AAAAAAAAA:::::A        L:::::L                   //
//    C:::::C                     A:::::A     A:::::A         L:::::L                   //
//    C:::::C                      A:::::A   A:::::A          L:::::L                   //
//    C:::::C                       A:::::A A:::::A           L:::::L                   //
//    C:::::C                        A:::::A:::::A            L:::::L                   //
//     C:::::C       CCCCCC           A:::::::::A             L:::::L                   //
//      C:::::CCCCCCCC::::C            A:::::::A            LL:::::::LL                 //
//         CCC::::::::::::C              A:::A              L:::::::::L                 //
//            CCCCCCCCCCCCC               AAA               LLLLLLLLLLL                 //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract SOAR is ERC721Creator {
    constructor() ERC721Creator("Perspective", "SOAR") {}
}