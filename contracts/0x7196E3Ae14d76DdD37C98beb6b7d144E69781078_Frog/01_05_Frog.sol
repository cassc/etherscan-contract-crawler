// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ether Frog
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Frog moment     //
//                    //
//                    //
////////////////////////


contract Frog is ERC721Creator {
    constructor() ERC721Creator("Ether Frog", "Frog") {}
}