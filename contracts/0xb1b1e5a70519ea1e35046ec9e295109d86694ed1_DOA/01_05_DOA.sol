// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dead On Arrival
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//     ▄▄▄▄▄▄  ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄     //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract DOA is ERC721Creator {
    constructor() ERC721Creator("Dead On Arrival", "DOA") {}
}