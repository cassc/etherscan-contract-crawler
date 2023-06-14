// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE SIMPSONZ
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    THE SIMPSONZ BY BLEO     //
//                             //
//                             //
/////////////////////////////////


contract BLEO is ERC1155Creator {
    constructor() ERC1155Creator("THE SIMPSONZ", "BLEO") {}
}