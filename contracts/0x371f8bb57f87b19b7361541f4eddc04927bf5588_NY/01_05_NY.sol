// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: New Years
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    REJELL    //
//              //
//              //
//////////////////


contract NY is ERC1155Creator {
    constructor() ERC1155Creator("New Years", "NY") {}
}