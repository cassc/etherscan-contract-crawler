// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Works by Fiat broke
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Works by Fiat broke    //
//                           //
//                           //
///////////////////////////////


contract WBFB is ERC721Creator {
    constructor() ERC721Creator("Works by Fiat broke", "WBFB") {}
}