// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: La Brea by Dy Mokomi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    La Brea         //
//    by Dy Mokomi    //
//                    //
//                    //
////////////////////////


contract LABREA is ERC721Creator {
    constructor() ERC721Creator("La Brea by Dy Mokomi", "LABREA") {}
}