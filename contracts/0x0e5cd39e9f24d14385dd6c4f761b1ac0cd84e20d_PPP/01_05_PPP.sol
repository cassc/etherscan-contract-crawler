// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pipipi collection ！！
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    ぴぴぴのコレクションだよ！    //
//                     //
//                     //
/////////////////////////


contract PPP is ERC721Creator {
    constructor() ERC721Creator(unicode"pipipi collection ！！", "PPP") {}
}