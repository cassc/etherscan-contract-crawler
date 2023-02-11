// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anatomy of the sky
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//     I   C   T   7     //
//      __   __   __     //
//     /  | /  | /       //
//    (___|(   |(___     //
//    |   )|   )    )    //
//    |  / |__/  __/     //
//                       //
//                       //
///////////////////////////


contract AOS is ERC1155Creator {
    constructor() ERC1155Creator("Anatomy of the sky", "AOS") {}
}