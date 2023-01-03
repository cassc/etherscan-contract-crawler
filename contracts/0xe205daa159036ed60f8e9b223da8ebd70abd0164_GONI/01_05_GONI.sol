// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GONI EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Here for the art!    //
//                         //
//                         //
/////////////////////////////


contract GONI is ERC1155Creator {
    constructor() ERC1155Creator("GONI EDITIONS", "GONI") {}
}