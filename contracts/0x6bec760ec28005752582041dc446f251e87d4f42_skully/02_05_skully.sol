// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Check Your Skull
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//      _____      //
//     /     \     //
//    | () () |    //
//     \  ^  /     //
//      |||||      //
//     NOTABLE     //
//      SKULL      //
//                 //
//                 //
/////////////////////


contract skully is ERC1155Creator {
    constructor() ERC1155Creator("Check Your Skull", "skully") {}
}