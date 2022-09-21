// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VLZ by Gavin Shapiro
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//         _______               __             _______ __                 __                     //
//        |     __|.---.-.--.--.|__|.-----.    |     __|  |--.---.-.-----.|__|.----.-----.        //
//        |    |  ||  _  |  |  ||  ||     |    |__     |     |  _  |  _  ||  ||   _|  _  |        //
//        |_______||___._|\___/ |__||__|__|    |_______|__|__|___._|   __||__||__| |_____|        //
//                                                                 |__|                           //
//                                                                                                //
//                                                                                                //
//        VVVVVVVV           VVVVVVVV     LLLLLLLLLLL                  ZZZZZZZZZZZZZZZZZZZ        //
//        V::::::V           V::::::V     L:::::::::L                  Z:::::::::::::::::Z        //
//        V::::::V           V::::::V     L:::::::::L                  Z:::::::::::::::::Z        //
//        V::::::V           V::::::V     LL:::::::LL                  Z:::ZZZZZZZZ:::::Z         //
//         V:::::V           V:::::V        L:::::L                    ZZZZZ     Z:::::Z          //
//          V:::::V         V:::::V         L:::::L                            Z:::::Z            //
//           V:::::V       V:::::V          L:::::L                           Z:::::Z             //
//            V:::::V     V:::::V           L:::::L                          Z:::::Z              //
//             V:::::V   V:::::V            L:::::L                         Z:::::Z               //
//              V:::::V V:::::V             L:::::L                        Z:::::Z                //
//               V:::::V:::::V              L:::::L                       Z:::::Z                 //
//                V:::::::::V               L:::::L         LLLLLL     ZZZ:::::Z     ZZZZZ        //
//                 V:::::::V              LL:::::::LLLLLLLLL:::::L     Z::::::ZZZZZZZZ:::Z        //
//                  V:::::V               L::::::::::::::::::::::L     Z:::::::::::::::::Z        //
//                   V:::V                L::::::::::::::::::::::L     Z:::::::::::::::::Z        //
//                    VVV                 LLLLLLLLLLLLLLLLLLLLLLLL     ZZZZZZZZZZZZZZZZZZZ        //
//                                                                                                //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract VLZ is ERC721Creator {
    constructor() ERC721Creator("VLZ by Gavin Shapiro", "VLZ") {}
}