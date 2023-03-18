// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The 7126
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    7126    //
//            //
//            //
////////////////


contract Art7126 is ERC1155Creator {
    constructor() ERC1155Creator("The 7126", "Art7126") {}
}