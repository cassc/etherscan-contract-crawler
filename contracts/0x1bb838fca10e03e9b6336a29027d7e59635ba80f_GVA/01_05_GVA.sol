// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gun Violence Archives
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    🚫    //
//          //
//          //
//////////////


contract GVA is ERC1155Creator {
    constructor() ERC1155Creator("Gun Violence Archives", "GVA") {}
}