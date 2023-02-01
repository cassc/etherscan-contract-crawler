// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peak OE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    PEAK    //
//            //
//            //
////////////////


contract Peak is ERC1155Creator {
    constructor() ERC1155Creator("Peak OE", "Peak") {}
}