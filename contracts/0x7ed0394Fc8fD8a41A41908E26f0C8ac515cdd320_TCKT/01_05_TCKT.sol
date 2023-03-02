// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sunny Ticket
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//       ≧◉◡◉≦       //
//    your ticket    //
//                   //
//                   //
///////////////////////


contract TCKT is ERC721Creator {
    constructor() ERC721Creator("Sunny Ticket", "TCKT") {}
}