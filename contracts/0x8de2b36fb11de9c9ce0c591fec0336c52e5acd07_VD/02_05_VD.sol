// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Von Doyle
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//                                                                              //
//                                                                              //
//                                                                              //
//    VVVVVVVV           VVVVVVVV     OOOOOOOOO     NNNNNNNN        NNNNNNNN    //
//    V::::::V           V::::::V   OO:::::::::OO   N:::::::N       N::::::N    //
//    V::::::V           V::::::V OO:::::::::::::OO N::::::::N      N::::::N    //
//    V::::::V           V::::::VO:::::::OOO:::::::ON:::::::::N     N::::::N    //
//     V:::::V           V:::::V O::::::O   O::::::ON::::::::::N    N::::::N    //
//      V:::::V         V:::::V  O:::::O     O:::::ON:::::::::::N   N::::::N    //
//       V:::::V       V:::::V   O:::::O     O:::::ON:::::::N::::N  N::::::N    //
//        V:::::V     V:::::V    O:::::O     O:::::ON::::::N N::::N N::::::N    //
//         V:::::V   V:::::V     O:::::O     O:::::ON::::::N  N::::N:::::::N    //
//          V:::::V V:::::V      O:::::O     O:::::ON::::::N   N:::::::::::N    //
//           V:::::V:::::V       O:::::O     O:::::ON::::::N    N::::::::::N    //
//            V:::::::::V        O::::::O   O::::::ON::::::N     N:::::::::N    //
//             V:::::::V         O:::::::OOO:::::::ON::::::N      N::::::::N    //
//              V:::::V           OO:::::::::::::OO N::::::N       N:::::::N    //
//               V:::V              OO:::::::::OO   N::::::N        N::::::N    //
//                VVV                 OOOOOOOOO     NNNNNNNN         NNNNNNN    //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract VD is ERC721Creator {
    constructor() ERC721Creator("Von Doyle", "VD") {}
}