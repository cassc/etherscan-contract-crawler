// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RAF Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//        _______  _______    _______     //
//      ╱╱       ╲╱       ╲╲╱╱       ╲    //
//     ╱╱        ╱        ╱╱╱      __╱    //
//    ╱        _╱         ╱        _╱     //
//    ╲____╱___╱╲___╱____╱╲_______╱       //
//                                        //
//                                        //
////////////////////////////////////////////


contract RED is ERC1155Creator {
    constructor() ERC1155Creator("RAF Editions", "RED") {}
}