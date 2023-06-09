// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lumina
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//    The Official 1/1 Contract for the "Lumina" Collection 🔅    //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract Light is ERC721Creator {
    constructor() ERC721Creator("Lumina", "Light") {}
}