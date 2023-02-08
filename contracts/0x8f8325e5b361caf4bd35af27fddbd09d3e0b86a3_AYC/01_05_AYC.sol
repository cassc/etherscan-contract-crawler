// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Add Your Caption
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract AYC is ERC1155Creator {
    constructor() ERC1155Creator("Add Your Caption", "AYC") {}
}