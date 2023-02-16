// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: daoTest
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Just a test    //
//                   //
//                   //
///////////////////////


contract daoTst is ERC721Creator {
    constructor() ERC721Creator("daoTest", "daoTst") {}
}