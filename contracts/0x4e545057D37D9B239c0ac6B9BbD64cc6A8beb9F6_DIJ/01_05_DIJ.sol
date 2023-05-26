// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Day in Japan
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    conte_digital    //
//                     //
//                     //
/////////////////////////


contract DIJ is ERC721Creator {
    constructor() ERC721Creator("A Day in Japan", "DIJ") {}
}