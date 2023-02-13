// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TCT Test Main
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    hi    //
//          //
//          //
//////////////


contract TCTTM is ERC1155Creator {
    constructor() ERC1155Creator("TCT Test Main", "TCTTM") {}
}