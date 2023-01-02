// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dark by Dy Mokomi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Dark            //
//    by Dy Mokomi    //
//                    //
//                    //
////////////////////////


contract DARK is ERC721Creator {
    constructor() ERC721Creator("Dark by Dy Mokomi", "DARK") {}
}