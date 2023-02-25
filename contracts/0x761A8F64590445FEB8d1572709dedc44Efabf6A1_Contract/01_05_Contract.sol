// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Contract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    Test    //
//            //
//            //
////////////////


contract Contract is ERC721Creator {
    constructor() ERC721Creator("Test Contract", "Contract") {}
}