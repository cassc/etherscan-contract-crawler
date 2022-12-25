// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BALLET
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    ballet    //
//              //
//              //
//////////////////


contract Ballet is ERC1155Creator {
    constructor() ERC1155Creator("BALLET", "Ballet") {}
}