// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE KiTCHEN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Welcome to THE KiTCHEN.    //
//                               //
//                               //
///////////////////////////////////


contract CHEF is ERC721Creator {
    constructor() ERC721Creator("THE KiTCHEN", "CHEF") {}
}