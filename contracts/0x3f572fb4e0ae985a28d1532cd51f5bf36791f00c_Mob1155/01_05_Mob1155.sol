// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1155mob
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    ping    //
//            //
//            //
////////////////


contract Mob1155 is ERC1155Creator {
    constructor() ERC1155Creator("1155mob", "Mob1155") {}
}