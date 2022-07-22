// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TOONZ999
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    TOONZ999    //
//                //
//                //
////////////////////


contract TOONZ999 is ERC721Creator {
    constructor() ERC721Creator("TOONZ999", "TOONZ999") {}
}