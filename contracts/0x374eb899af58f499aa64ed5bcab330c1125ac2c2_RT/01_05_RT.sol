// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reaper town
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    RT    //
//          //
//          //
//////////////


contract RT is ERC1155Creator {
    constructor() ERC1155Creator("Reaper town", "RT") {}
}