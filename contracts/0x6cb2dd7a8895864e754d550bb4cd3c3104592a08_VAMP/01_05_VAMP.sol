// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Necks - OvvO Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    VV    //
//          //
//          //
//////////////


contract VAMP is ERC1155Creator {
    constructor() ERC1155Creator("Necks - OvvO Edition", "VAMP") {}
}