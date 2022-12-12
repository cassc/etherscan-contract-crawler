// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 21
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    👁    //
//          //
//          //
//////////////


contract FREEDOM is ERC1155Creator {
    constructor() ERC1155Creator("21", "FREEDOM") {}
}