// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mike-Josh
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    MJ art    //
//              //
//              //
//////////////////


contract MJMJ is ERC721Creator {
    constructor() ERC721Creator("Mike-Josh", "MJMJ") {}
}