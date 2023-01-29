// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Token
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    NU    //
//          //
//          //
//////////////


contract NU is ERC721Creator {
    constructor() ERC721Creator("Test Token", "NU") {}
}