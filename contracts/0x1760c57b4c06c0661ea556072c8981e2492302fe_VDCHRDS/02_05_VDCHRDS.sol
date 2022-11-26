// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Void_Chords×RWBY Demo Song Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//       ________   ______    _______  _______    _______   ______   ________     //
//      ╱    ╱   ╲_╱      ╲╲╱╱       ╲╱    ╱  ╲╲╱╱       ╲_╱      ╲╲╱        ╲    //
//     ╱         ╱        ╱╱╱        ╱        ╱╱╱        ╱        ╱╱        _╱    //
//     ╲        ╱         ╱       --╱         ╱        _╱         ╱-        ╱     //
//      ╲╲_____╱╲________╱╲________╱╲___╱____╱╲____╱___╱╲________╱╲_______╱╱      //
//                                                                                //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract VDCHRDS is ERC721Creator {
    constructor() ERC721Creator(unicode"Void_Chords×RWBY Demo Song Collection", "VDCHRDS") {}
}