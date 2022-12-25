// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: やどかり
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    テスト    //
//           //
//           //
///////////////


contract YADOKARI is ERC721Creator {
    constructor() ERC721Creator(unicode"やどかり", "YADOKARI") {}
}