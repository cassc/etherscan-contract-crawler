// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3LAND COSMIC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    3LAND COSMIC    //
//                    //
//                    //
////////////////////////


contract CM3L is ERC721Creator {
    constructor() ERC721Creator("3LAND COSMIC", "CM3L") {}
}