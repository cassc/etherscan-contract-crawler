// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PALM TREE FARM
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    🌴    //
//          //
//          //
//////////////


contract PTF is ERC1155Creator {
    constructor() ERC1155Creator("PALM TREE FARM", "PTF") {}
}