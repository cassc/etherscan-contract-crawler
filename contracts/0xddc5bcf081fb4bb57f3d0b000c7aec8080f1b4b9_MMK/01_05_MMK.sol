// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: テスト
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    (,,･ω･,,)    //
//                 //
//                 //
/////////////////////


contract MMK is ERC721Creator {
    constructor() ERC721Creator(unicode"テスト", "MMK") {}
}