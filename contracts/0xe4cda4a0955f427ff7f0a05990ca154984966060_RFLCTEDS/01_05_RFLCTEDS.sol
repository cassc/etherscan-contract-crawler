// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reflections
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    Art by Solemn    //
//                     //
//                     //
/////////////////////////


contract RFLCTEDS is ERC1155Creator {
    constructor() ERC1155Creator("Reflections", "RFLCTEDS") {}
}