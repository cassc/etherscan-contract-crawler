// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test AON Name
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    prapas    //
//              //
//              //
//////////////////


contract AON is ERC721Creator {
    constructor() ERC721Creator("Test AON Name", "AON") {}
}