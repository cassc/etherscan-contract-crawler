// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: facepAInt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//         OOOOOOOOO             GGGGGGGGGGGGG     DDDDDDDDDDDDD                  AAA               NNNNNNNN        NNNNNNNN    //
//       OO:::::::::OO        GGG::::::::::::G     D::::::::::::DDD              A:::A              N:::::::N       N::::::N    //
//     OO:::::::::::::OO    GG:::::::::::::::G     D:::::::::::::::DD           A:::::A             N::::::::N      N::::::N    //
//    O:::::::OOO:::::::O  G:::::GGGGGGGG::::G     DDD:::::DDDDD:::::D         A:::::::A            N:::::::::N     N::::::N    //
//    O::::::O   O::::::O G:::::G       GGGGGG       D:::::D    D:::::D       A:::::::::A           N::::::::::N    N::::::N    //
//    O:::::O     O:::::OG:::::G                     D:::::D     D:::::D     A:::::A:::::A          N:::::::::::N   N::::::N    //
//    O:::::O     O:::::OG:::::G                     D:::::D     D:::::D    A:::::A A:::::A         N:::::::N::::N  N::::::N    //
//    O:::::O     O:::::OG:::::G    GGGGGGGGGG       D:::::D     D:::::D   A:::::A   A:::::A        N::::::N N::::N N::::::N    //
//    O:::::O     O:::::OG:::::G    G::::::::G       D:::::D     D:::::D  A:::::A     A:::::A       N::::::N  N::::N:::::::N    //
//    O:::::O     O:::::OG:::::G    GGGGG::::G       D:::::D     D:::::D A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::N    //
//    O:::::O     O:::::OG:::::G        G::::G       D:::::D     D:::::DA:::::::::::::::::::::A     N::::::N    N::::::::::N    //
//    O::::::O   O::::::O G:::::G       G::::G       D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::N    //
//    O:::::::OOO:::::::O  G:::::GGGGGGGG::::G     DDD:::::DDDDD:::::DA:::::A             A:::::A   N::::::N      N::::::::N    //
//     OO:::::::::::::OO    GG:::::::::::::::G     D:::::::::::::::DDA:::::A               A:::::A  N::::::N       N:::::::N    //
//       OO:::::::::OO        GGG::::::GGG:::G     D::::::::::::DDD A:::::A                 A:::::A N::::::N        N::::::N    //
//         OOOOOOOOO             GGGGGG   GGGG     DDDDDDDDDDDDD   AAAAAAA                   AAAAAAANNNNNNNN         NNNNNNN    //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FACE is ERC721Creator {
    constructor() ERC721Creator("facepAInt", "FACE") {}
}