// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dr jones
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    pipa    //
//            //
//            //
////////////////


contract drj is ERC721Creator {
    constructor() ERC721Creator("dr jones", "drj") {}
}