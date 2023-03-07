// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gabe Weis Burnables
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    GWBURN    //
//              //
//              //
//////////////////


contract GWBURN is ERC1155Creator {
    constructor() ERC1155Creator("Gabe Weis Burnables", "GWBURN") {}
}