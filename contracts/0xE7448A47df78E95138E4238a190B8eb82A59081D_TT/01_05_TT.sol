// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Thread
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    🧵    //
//          //
//          //
//////////////


contract TT is ERC1155Creator {
    constructor() ERC1155Creator("The Thread", "TT") {}
}