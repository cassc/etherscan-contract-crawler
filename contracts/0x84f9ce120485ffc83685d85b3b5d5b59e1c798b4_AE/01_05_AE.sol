// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arteestic Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    𝑨𝒓𝒕𝒆𝒆𝒔𝒕𝒊𝒄    //
//                          //
//                          //
//////////////////////////////


contract AE is ERC1155Creator {
    constructor() ERC1155Creator("Arteestic Editions", "AE") {}
}