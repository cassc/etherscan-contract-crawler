// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CYBERSMOWLS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    SMOWLONCYBER    //
//                    //
//                    //
////////////////////////


contract CSML is ERC1155Creator {
    constructor() ERC1155Creator("CYBERSMOWLS", "CSML") {}
}