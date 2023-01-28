// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nayn Balloon
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    NAYN BALLOON    //
//                    //
//                    //
////////////////////////


contract NAYN is ERC721Creator {
    constructor() ERC721Creator("Nayn Balloon", "NAYN") {}
}