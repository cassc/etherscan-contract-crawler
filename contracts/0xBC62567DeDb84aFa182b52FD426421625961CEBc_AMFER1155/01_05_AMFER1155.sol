// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AMFERS EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    :o    //
//          //
//          //
//////////////


contract AMFER1155 is ERC1155Creator {
    constructor() ERC1155Creator("AMFERS EDITIONS", "AMFER1155") {}
}