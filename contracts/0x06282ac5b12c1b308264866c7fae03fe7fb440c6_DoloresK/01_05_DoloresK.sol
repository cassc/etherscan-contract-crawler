// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dolores2850 ERC 1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    DoloresK    //
//                //
//                //
////////////////////


contract DoloresK is ERC1155Creator {
    constructor() ERC1155Creator("Dolores2850 ERC 1155", "DoloresK") {}
}