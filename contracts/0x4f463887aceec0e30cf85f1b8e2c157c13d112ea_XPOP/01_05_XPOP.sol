// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ExPopulus
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    XPOP    //
//            //
//            //
////////////////


contract XPOP is ERC721Creator {
    constructor() ERC721Creator("ExPopulus", "XPOP") {}
}