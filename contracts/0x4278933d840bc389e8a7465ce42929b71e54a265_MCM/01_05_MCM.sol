// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: METACROMAGNON OPEN EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    MCM02.TAC    //
//                 //
//                 //
/////////////////////


contract MCM is ERC1155Creator {
    constructor() ERC1155Creator("METACROMAGNON OPEN EDITIONS", "MCM") {}
}