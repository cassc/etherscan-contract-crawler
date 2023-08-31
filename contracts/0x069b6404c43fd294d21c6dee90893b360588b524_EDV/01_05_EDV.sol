// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EDVENT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    EdV3nT    //
//              //
//              //
//////////////////


contract EDV is ERC1155Creator {
    constructor() ERC1155Creator("EDVENT", "EDV") {}
}