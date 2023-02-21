// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The girl and her cats
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    meow    //
//            //
//            //
////////////////


contract CAT is ERC1155Creator {
    constructor() ERC1155Creator("The girl and her cats", "CAT") {}
}