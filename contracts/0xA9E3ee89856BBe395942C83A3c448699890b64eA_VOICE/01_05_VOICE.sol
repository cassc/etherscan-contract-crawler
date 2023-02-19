// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dear Opensea
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract VOICE is ERC1155Creator {
    constructor() ERC1155Creator("Dear Opensea", "VOICE") {}
}