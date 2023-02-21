// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LilTea Pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    LilTea Pass    //
//                   //
//                   //
///////////////////////


contract LTP is ERC721Creator {
    constructor() ERC721Creator("LilTea Pass", "LTP") {}
}