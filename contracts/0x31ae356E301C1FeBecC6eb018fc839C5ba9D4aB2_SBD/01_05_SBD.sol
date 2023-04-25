// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: B-Day Cake
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    SNOWBD    //
//              //
//              //
//////////////////


contract SBD is ERC1155Creator {
    constructor() ERC1155Creator("B-Day Cake", "SBD") {}
}