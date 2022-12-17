// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GIRLS YOU KNOW BY CATCH_U
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//    ▒█▀▀█ ▀█▀ ▒█▀▀█ ▒█░░░ ▒█▀▀▀█ 　 ▒█░░▒█ ▒█▀▀▀█ ▒█░▒█ 　 ▒█░▄▀ ▒█▄░▒█ ▒█▀▀▀█ ▒█░░▒█     //
//    ▒█░▄▄ ▒█░ ▒█▄▄▀ ▒█░░░ ░▀▀▀▄▄ 　 ▒█▄▄▄█ ▒█░░▒█ ▒█░▒█ 　 ▒█▀▄░ ▒█▒█▒█ ▒█░░▒█ ▒█▒█▒█     //
//    ▒█▄▄█ ▄█▄ ▒█░▒█ ▒█▄▄█ ▒█▄▄▄█ 　 ░░▒█░░ ▒█▄▄▄█ ░▀▄▄▀ 　 ▒█░▒█ ▒█░░▀█ ▒█▄▄▄█ ▒█▄▀▄█     //
//                                                                                        //
//    CREATOR DARIA SUKHANOVA A.K.A CATCH_U                                               //
//    OPENSEA -CATCH_U-                                                                   //
//    TWITTER CATCH__U                                                                    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract GYK is ERC1155Creator {
    constructor() ERC1155Creator("GIRLS YOU KNOW BY CATCH_U", "GYK") {}
}