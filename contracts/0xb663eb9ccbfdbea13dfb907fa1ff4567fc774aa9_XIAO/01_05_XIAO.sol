// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TEST01
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    TEST01    //
//              //
//              //
//////////////////


contract XIAO is ERC721Creator {
    constructor() ERC721Creator("TEST01", "XIAO") {}
}