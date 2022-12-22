// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pp+m
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    padre on bull    //
//                     //
//                     //
/////////////////////////


contract pp is ERC721Creator {
    constructor() ERC721Creator("pp+m", "pp") {}
}