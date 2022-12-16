// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art from Heart
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    ARTRCT    //
//              //
//              //
//////////////////


contract ARTRCT is ERC721Creator {
    constructor() ERC721Creator("Art from Heart", "ARTRCT") {}
}