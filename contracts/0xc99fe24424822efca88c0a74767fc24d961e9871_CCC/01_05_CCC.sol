// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ちびきゃらこれくしょん！
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    CCC    //
//           //
//           //
///////////////


contract CCC is ERC721Creator {
    constructor() ERC721Creator(unicode"ちびきゃらこれくしょん！", "CCC") {}
}