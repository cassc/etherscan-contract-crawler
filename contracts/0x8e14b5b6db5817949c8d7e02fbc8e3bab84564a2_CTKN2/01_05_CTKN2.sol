// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ClaimTkn#2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    CTKN#2    //
//              //
//              //
//////////////////


contract CTKN2 is ERC1155Creator {
    constructor() ERC1155Creator("ClaimTkn#2", "CTKN2") {}
}