// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    XO    //
//          //
//          //
//////////////


contract XO is ERC721Creator {
    constructor() ERC721Creator("XO", "XO") {}
}