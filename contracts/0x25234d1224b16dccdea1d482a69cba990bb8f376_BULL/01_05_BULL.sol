// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BULL BTC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    BULL BTC    //
//                //
//                //
////////////////////


contract BULL is ERC721Creator {
    constructor() ERC721Creator("BULL BTC", "BULL") {}
}