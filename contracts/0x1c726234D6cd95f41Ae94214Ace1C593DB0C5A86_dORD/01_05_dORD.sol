// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: disORDerly Ordinals
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                dddddddd                                                                //
//                d::::::d     OOOOOOOOO     RRRRRRRRRRRRRRRRR   DDDDDDDDDDDDD            //
//                d::::::d   OO:::::::::OO   R::::::::::::::::R  D::::::::::::DDD         //
//                d::::::d OO:::::::::::::OO R::::::RRRRRR:::::R D:::::::::::::::DD       //
//                d:::::d O:::::::OOO:::::::ORR:::::R     R:::::RDDD:::::DDDDD:::::D      //
//        ddddddddd:::::d O::::::O   O::::::O  R::::R     R:::::R  D:::::D    D:::::D     //
//      dd::::::::::::::d O:::::O     O:::::O  R::::R     R:::::R  D:::::D     D:::::D    //
//     d::::::::::::::::d O:::::O     O:::::O  R::::RRRRRR:::::R   D:::::D     D:::::D    //
//    d:::::::ddddd:::::d O:::::O     O:::::O  R:::::::::::::RR    D:::::D     D:::::D    //
//    d::::::d    d:::::d O:::::O     O:::::O  R::::RRRRRR:::::R   D:::::D     D:::::D    //
//    d:::::d     d:::::d O:::::O     O:::::O  R::::R     R:::::R  D:::::D     D:::::D    //
//    d:::::d     d:::::d O:::::O     O:::::O  R::::R     R:::::R  D:::::D     D:::::D    //
//    d:::::d     d:::::d O::::::O   O::::::O  R::::R     R:::::R  D:::::D    D:::::D     //
//    d::::::ddddd::::::ddO:::::::OOO:::::::ORR:::::R     R:::::RDDD:::::DDDDD:::::D      //
//     d:::::::::::::::::d OO:::::::::::::OO R::::::R     R:::::RD:::::::::::::::DD       //
//      d:::::::::ddd::::d   OO:::::::::OO   R::::::R     R:::::RD::::::::::::DDD         //
//       ddddddddd   ddddd     OOOOOOOOO     RRRRRRRR     RRRRRRRDDDDDDDDDDDDD            //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract dORD is ERC721Creator {
    constructor() ERC721Creator("disORDerly Ordinals", "dORD") {}
}