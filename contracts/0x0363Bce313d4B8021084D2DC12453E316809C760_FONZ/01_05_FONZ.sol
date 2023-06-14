// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fonzi Scheme
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    🪩    //
//          //
//          //
//////////////


contract FONZ is ERC1155Creator {
    constructor() ERC1155Creator("Fonzi Scheme", "FONZ") {}
}