// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fire Card Company
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Fire Card Company    //
//                         //
//                         //
/////////////////////////////


contract FireCard is ERC721Creator {
    constructor() ERC721Creator("Fire Card Company", "FireCard") {}
}