// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: なめがたしをみコレクション
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    遊んでくれてありがとね    //
//                   //
//                   //
///////////////////////


contract MSC is ERC721Creator {
    constructor() ERC721Creator(unicode"なめがたしをみコレクション", "MSC") {}
}