// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BATTLE test
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    ┈┈┈☆☆☆☆☆☆☆☆☆┈┈┈    //
//    ┈┈╭┻┻┻┻┻┻┻┻┻╮┈┈    //
//    ┈┈┃╱╲╱╲╱╲╱╲╱┃┈┈    //
//    ┈╭┻━━━━━━━━━┻╮┈    //
//    ┈┃╱╲╱╲╱╲╱╲╱╲╱┃┈    //
//    ┈┗━━━━━━━━━━━┛┈    //
//                       //
//                       //
///////////////////////////


contract HBD is ERC721Creator {
    constructor() ERC721Creator("BATTLE test", "HBD") {}
}