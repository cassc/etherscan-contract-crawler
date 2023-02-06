// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FL69R -OpenEditon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//                                                           //
//      _______  ___         ___   _______     _______       //
//     /"     "||"  |       /. ") /" _   "\   /"      \      //
//    (: ______)||  |      /:  / (: (_/  :|  |:        |     //
//     \/    |  |:  |     //  /___\____/ |)  |_____/   )     //
//     // ___)   \  |___ (   / _  \  _\  '|   //      /      //
//    (:  (     ( \_|:  \|:   /_) :)/" \__|\ |:  __   \      //
//     \__/      \_______)\_______/(________)|__|  \___)     //
//                                                           //
//                                                           //
//    the open edition is life. free is even better          //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract OE is ERC1155Creator {
    constructor() ERC1155Creator("FL69R -OpenEditon", "OE") {}
}