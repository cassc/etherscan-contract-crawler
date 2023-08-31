// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Egypt Animal Care Pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    #animalcare    //
//                   //
//                   //
///////////////////////


contract AACP is ERC1155Creator {
    constructor() ERC1155Creator("Egypt Animal Care Pass", "AACP") {}
}