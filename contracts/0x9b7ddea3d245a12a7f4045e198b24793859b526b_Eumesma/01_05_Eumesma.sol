// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ingridi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    Descentralização, liberdade e conhecimento     //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract Eumesma is ERC721Creator {
    constructor() ERC721Creator("Ingridi", "Eumesma") {}
}