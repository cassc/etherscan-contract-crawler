// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: the revolution will be minted
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//     _______________     //
//    | /~~~~~~~~\ ||||    //
//    ||          |...|    //
//    ||          |   |    //
//    | \________/  O |    //
//     ~~~~~~~~~~~~~~~     //
//                         //
//                         //
/////////////////////////////


contract trwbm is ERC721Creator {
    constructor() ERC721Creator("the revolution will be minted", "trwbm") {}
}