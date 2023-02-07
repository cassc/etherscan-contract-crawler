// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: release.last
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    *sigh*    //
//              //
//              //
//////////////////


contract rlst is ERC721Creator {
    constructor() ERC721Creator("release.last", "rlst") {}
}