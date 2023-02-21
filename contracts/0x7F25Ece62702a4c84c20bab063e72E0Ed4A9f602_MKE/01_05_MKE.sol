// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Maxwell Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//    ooo_____ooo___________________________________ooo___ooo___    //
//    oooo___oooo__ooooo__o____o_oo_______o__ooooo___oo____oo___    //
//    oo_oo_oo_oo_oo___oo__oo_o__oo__oo___o_oo____o__oo____oo___    //
//    oo__ooo__oo_oo___oo___oo___oo__oo___o_ooooooo__oo____oo___    //
//    oo_______oo_oo___oo__o_oo___oo_oo__o__oo_______oo____oo___    //
//    oo_______oo__oooo_o_o___oo___oo__oo____ooooo__ooooo_ooooo_    //
//    __________________________________________________________    //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract MKE is ERC1155Creator {
    constructor() ERC1155Creator("Maxwell Editions", "MKE") {}
}