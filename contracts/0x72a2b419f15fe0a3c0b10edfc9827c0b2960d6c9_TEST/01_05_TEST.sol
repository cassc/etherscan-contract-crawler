// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TestTest
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    ////Test////    //
//                    //
//                    //
////////////////////////


contract TEST is ERC721Creator {
    constructor() ERC721Creator("TestTest", "TEST") {}
}