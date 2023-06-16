// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Stitch in Time
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//    _____.___._______    _________      //
//    \__  |   |\      \  /   _____/      //
//     /   |   |/   |   \ \_____  \       //
//     \____   /    |    \/        \      //
//     / ______\____|__  /_______  /      //
//     \/              \/        \/       //
//    Digital Artist | Motion Designer    //
//                                        //
//                                        //
////////////////////////////////////////////


contract AST is ERC721Creator {
    constructor() ERC721Creator("A Stitch in Time", "AST") {}
}