// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LFG 2023
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    TO THE MOON    //
//                   //
//                   //
///////////////////////


contract JKTLM is ERC1155Creator {
    constructor() ERC1155Creator("LFG 2023", "JKTLM") {}
}