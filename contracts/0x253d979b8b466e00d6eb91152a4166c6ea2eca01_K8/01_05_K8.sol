// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KANDRO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Philosopher     //
//                    //
//                    //
////////////////////////


contract K8 is ERC721Creator {
    constructor() ERC721Creator("KANDRO", "K8") {}
}