// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ACHE WORLD
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//      _______    _______  _______    _______      //
//      ╱       ╲╲╱╱       ╲╱    ╱  ╲╲╱╱       ╲    //
//     ╱        ╱╱╱        ╱        ╱╱╱        ╱    //
//    ╱         ╱       --╱         ╱        _╱     //
//    ╲___╱____╱╲________╱╲___╱____╱╲________╱      //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract aCHe is ERC1155Creator {
    constructor() ERC1155Creator("ACHE WORLD", "aCHe") {}
}