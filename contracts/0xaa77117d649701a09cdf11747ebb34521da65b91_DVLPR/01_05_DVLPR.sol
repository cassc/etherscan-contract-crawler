// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Developer
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//        ______   ________   ______   ________   _______     //
//      _╱      ╲╲╱    ╱   ╲╱╱      ╲ ╱        ╲╱╱       ╲    //
//     ╱        ╱╱         ╱╱       ╱╱         ╱╱        ╱    //
//    ╱         ╱╲        ╱        ╱╱╱      __╱        _╱     //
//    ╲________╱  ╲╲_____╱╲________╱╲╲_____╱  ╲____╱___╱      //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract DVLPR is ERC1155Creator {
    constructor() ERC1155Creator("Developer", "DVLPR") {}
}