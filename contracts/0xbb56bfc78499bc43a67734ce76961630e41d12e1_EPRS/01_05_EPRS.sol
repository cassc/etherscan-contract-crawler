// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Epirus
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Epirus by greek_nft    //
//                           //
//                           //
///////////////////////////////


contract EPRS is ERC1155Creator {
    constructor() ERC1155Creator("Epirus", "EPRS") {}
}