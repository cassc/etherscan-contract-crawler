// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: alone.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    30brac was here    //
//                       //
//                       //
///////////////////////////


contract SOLO is ERC1155Creator {
    constructor() ERC1155Creator("alone.", "SOLO") {}
}