// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ERC721tst-with dev
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    devtst    //
//              //
//              //
//////////////////


contract devtst is ERC721Creator {
    constructor() ERC721Creator("ERC721tst-with dev", "devtst") {}
}