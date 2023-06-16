// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spike Art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract SART is ERC1155Creator {
    constructor() ERC1155Creator("Spike Art", "SART") {}
}