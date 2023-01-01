// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meander
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    <:-)    //
//            //
//            //
////////////////


contract MUSE is ERC1155Creator {
    constructor() ERC1155Creator("Meander", "MUSE") {}
}