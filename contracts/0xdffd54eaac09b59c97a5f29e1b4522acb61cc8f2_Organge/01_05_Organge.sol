// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Orange Lights
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Art by Leni Amber    //
//                         //
//                         //
/////////////////////////////


contract Organge is ERC1155Creator {
    constructor() ERC1155Creator("Orange Lights", "Organge") {}
}