// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tear Gas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    🙈    //
//          //
//          //
//////////////


contract TGAS is ERC721Creator {
    constructor() ERC721Creator("Tear Gas", "TGAS") {}
}