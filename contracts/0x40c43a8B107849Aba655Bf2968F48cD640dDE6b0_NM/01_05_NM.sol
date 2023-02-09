// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nyan Mario
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    Nyan Mario    //
//                  //
//                  //
//////////////////////


contract NM is ERC1155Creator {
    constructor() ERC1155Creator("Nyan Mario", "NM") {}
}