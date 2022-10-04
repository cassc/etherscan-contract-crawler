// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test69
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract test69 is ERC721Creator {
    constructor() ERC721Creator("test69", "test69") {}
}