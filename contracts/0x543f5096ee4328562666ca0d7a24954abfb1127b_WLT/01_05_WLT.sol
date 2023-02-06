// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WILT.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    jatuur    //
//    </3       //
//              //
//              //
//////////////////


contract WLT is ERC1155Creator {
    constructor() ERC1155Creator("WILT.", "WLT") {}
}