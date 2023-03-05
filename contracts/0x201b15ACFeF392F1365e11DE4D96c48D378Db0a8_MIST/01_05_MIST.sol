// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MISTFITS TREASURE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    MISTFITS TREASURE    //
//                         //
//                         //
/////////////////////////////


contract MIST is ERC1155Creator {
    constructor() ERC1155Creator("MISTFITS TREASURE", "MIST") {}
}