// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RSF editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    ◉-◉¬    //
//            //
//            //
////////////////


contract RSFE is ERC1155Creator {
    constructor() ERC1155Creator("RSF editions", "RSFE") {}
}