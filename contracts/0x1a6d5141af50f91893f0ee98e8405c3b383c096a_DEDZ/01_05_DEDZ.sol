// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ded On Arrival
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//     ▄▄▄▄▄▄  ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄     //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract DEDZ is ERC721Creator {
    constructor() ERC721Creator("Ded On Arrival", "DEDZ") {}
}