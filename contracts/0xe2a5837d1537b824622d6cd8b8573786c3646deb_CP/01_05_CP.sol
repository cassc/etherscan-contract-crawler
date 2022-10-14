// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: arami Circle PASS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    arami circle pass    //
//                         //
//                         //
/////////////////////////////


contract CP is ERC721Creator {
    constructor() ERC721Creator("arami Circle PASS", "CP") {}
}