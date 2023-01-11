// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EVEN ENEMIES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    EVEN ENEMIES    //
//                    //
//                    //
////////////////////////


contract EE is ERC721Creator {
    constructor() ERC721Creator("EVEN ENEMIES", "EE") {}
}