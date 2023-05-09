// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memeyo-e
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    ฅ^•ﻌ•^ฅ    //
//               //
//               //
///////////////////


contract MMY is ERC721Creator {
    constructor() ERC721Creator("Memeyo-e", "MMY") {}
}