// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DO NOT MINT THIS SHIT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    DO NOT    //
//    MINT      //
//    THIS      //
//    SHIT      //
//              //
//              //
//////////////////


contract DNMTS is ERC1155Creator {
    constructor() ERC1155Creator("DO NOT MINT THIS SHIT", "DNMTS") {}
}