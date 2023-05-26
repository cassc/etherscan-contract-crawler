// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Turf Cartridges
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    oooooooo_oo______oo_ooooooo___ooooooo_             //
//    ___oo____oo______oo_oo____oo__oo______             //
//    ___oo____oo______oo_oo____oo__oooo____             //
//    ___oo____oo______oo_ooooooo___oo______             //
//    ___oo_____oo____oo__oo____oo__oo______             //
//    ___oo_______oooo____oo_____oo_oo______             //
//    ______________________________________             //
//    ___oooo______ooo____ooooooo___oooooooo__ooooo__    //
//    _oo____oo__oo___oo__oo____oo_____oo____oo___oo_    //
//    oo________oo_____oo_oo____oo_____oo_____oo_____    //
//    oo________ooooooooo_ooooooo______oo_______oo___    //
//    _oo____oo_oo_____oo_oo____oo_____oo____oo___oo_    //
//    ___oooo___oo_____oo_oo_____oo____oo_____ooooo__    //
//    _______________________________________________    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract TCOE is ERC1155Creator {
    constructor() ERC1155Creator("Turf Cartridges", "TCOE") {}
}