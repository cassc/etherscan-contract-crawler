// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DMPAJCBPN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    Skife made this    //
//                       //
//                       //
///////////////////////////


contract DMP is ERC1155Creator {
    constructor() ERC1155Creator("DMPAJCBPN", "DMP") {}
}