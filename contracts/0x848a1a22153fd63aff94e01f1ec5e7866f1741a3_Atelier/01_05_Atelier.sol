// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ayla Atelier
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Queen of Waves     //
//                       //
//                       //
///////////////////////////


contract Atelier is ERC721Creator {
    constructor() ERC721Creator("Ayla Atelier", "Atelier") {}
}