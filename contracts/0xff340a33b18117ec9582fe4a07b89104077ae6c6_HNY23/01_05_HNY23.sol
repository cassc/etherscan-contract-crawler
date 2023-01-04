// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HNY Rabbit 2023
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    Free claim    //
//                  //
//                  //
//////////////////////


contract HNY23 is ERC1155Creator {
    constructor() ERC1155Creator("HNY Rabbit 2023", "HNY23") {}
}