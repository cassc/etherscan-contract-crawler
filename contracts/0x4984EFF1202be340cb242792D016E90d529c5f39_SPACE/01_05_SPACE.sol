// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HKU SPACE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    HKU SPACE    //
//                 //
//                 //
/////////////////////


contract SPACE is ERC1155Creator {
    constructor() ERC1155Creator("HKU SPACE", "SPACE") {}
}