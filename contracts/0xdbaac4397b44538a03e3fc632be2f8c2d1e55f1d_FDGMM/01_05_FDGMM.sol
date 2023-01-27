// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FOUNDING MEMER
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                                                                          //
//       ________)                            __     __)                    //
//      (, /                 /) ,            (, /|  /|                      //
//        /___, ___   __   _(/   __   _        / | / |   _ ___    _  __     //
//     ) /     (_)(_(_/ (_(_(__(_/ (_(_/_   ) /  |/  |__(/_// (__(/_/ (_    //
//    (_/                           .-/    (_/   '                          //
//                                 (_/                                      //
//                                                                          //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract FDGMM is ERC1155Creator {
    constructor() ERC1155Creator("FOUNDING MEMER", "FDGMM") {}
}