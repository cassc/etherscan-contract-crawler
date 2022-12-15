// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Learning to love myself
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    BE    //
//          //
//          //
//////////////


contract BE is ERC1155Creator {
    constructor() ERC1155Creator("Learning to love myself", "BE") {}
}