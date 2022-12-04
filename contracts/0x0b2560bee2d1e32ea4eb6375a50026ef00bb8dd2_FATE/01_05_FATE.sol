// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fate Pass (OS Compliant)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    FATE    //
//            //
//            //
////////////////


contract FATE is ERC1155Creator {
    constructor() ERC1155Creator("Fate Pass (OS Compliant)", "FATE") {}
}