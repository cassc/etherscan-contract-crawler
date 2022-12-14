// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WMFG Special Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    WMFG    //
//            //
//            //
////////////////


contract WMFG is ERC721Creator {
    constructor() ERC721Creator("WMFG Special Editions", "WMFG") {}
}