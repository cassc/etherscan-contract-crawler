// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Dream Of Happiness
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//       _____   ________     ___ ___       //
//      /  _  \  \______ \   /   |   \      //
//     /  /_\  \  |    |  \ /    ~    \     //
//    /    |    \ |    `   \\    Y    /     //
//    \____|__  //_______  / \___|_  /      //
//            \/         \/        \/       //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract ADH is ERC1155Creator {
    constructor() ERC1155Creator("A Dream Of Happiness", "ADH") {}
}