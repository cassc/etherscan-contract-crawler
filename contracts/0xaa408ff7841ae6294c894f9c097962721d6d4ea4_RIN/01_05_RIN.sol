// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sachirin
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    o w o     //
//              //
//              //
//////////////////


contract RIN is ERC1155Creator {
    constructor() ERC1155Creator("Sachirin", "RIN") {}
}