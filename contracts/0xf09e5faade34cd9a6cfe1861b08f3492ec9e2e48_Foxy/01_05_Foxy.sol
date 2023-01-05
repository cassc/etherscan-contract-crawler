// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Foxy Roxy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    What does the 🦊 say?    //
//                             //
//                             //
/////////////////////////////////


contract Foxy is ERC1155Creator {
    constructor() ERC1155Creator("Foxy Roxy", "Foxy") {}
}