// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lebanese revolution
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                  //
//                                                                                                                                                  //
//                                                                                                                                                  //
//    ooo___________oo________________________________________________________________________________ooo____________oo_____oo__________________    //
//    _oo____ooooo__oooooo___ooooo__oo_ooo___ooooo___oooo___ooooo_____oo_ooo___ooooo__oo____o__ooooo___oo___oo____o__oo__________ooooo__oo_ooo__    //
//    _oo___oo____o_oo___oo_oo___oo_ooo___o_oo____o_oo___o_oo____o____ooo___o_oo____o_oo____o_oo___oo__oo___oo____o_oooo____oo__oo___oo_ooo___o_    //
//    _oo___ooooooo_oo___oo_oo___oo_oo____o_ooooooo___oo___ooooooo____oo______ooooooo_oo___o__oo___oo__oo___oo____o__oo_____oo__oo___oo_oo____o_    //
//    _oo___oo______oo___oo_oo___oo_oo____o_oo______o___oo_oo_________oo______oo_______oo_o___oo___oo__oo___ooo___o__oo__o__oo__oo___oo_oo____o_    //
//    ooooo__ooooo__oooooo___oooo_o_oo____o__ooooo___oooo___ooooo_____oo_______ooooo____oo_____ooooo__ooooo_oo_ooo____ooo__oooo__ooooo__oo____o_    //
//    __________________________________________________________________________________________________________________________________________    //
//                                                                                                                                                  //
//                                                                                                                                                  //
//                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LBP is ERC721Creator {
    constructor() ERC721Creator("Lebanese revolution", "LBP") {}
}