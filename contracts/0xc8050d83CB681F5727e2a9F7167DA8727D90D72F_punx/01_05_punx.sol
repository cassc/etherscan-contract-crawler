// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: punx 1/1s
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    punx    //
//            //
//            //
////////////////


contract punx is ERC721Creator {
    constructor() ERC721Creator("punx 1/1s", "punx") {}
}