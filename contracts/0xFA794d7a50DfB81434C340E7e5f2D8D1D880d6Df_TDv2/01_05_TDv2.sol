// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Testdoge v2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    TDv2    //
//            //
//            //
////////////////


contract TDv2 is ERC721Creator {
    constructor() ERC721Creator("Testdoge v2", "TDv2") {}
}