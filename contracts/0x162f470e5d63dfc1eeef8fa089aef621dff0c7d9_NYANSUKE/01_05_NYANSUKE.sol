// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gift from a cat
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    ฅ^•ω•^ฅ    //
//               //
//               //
///////////////////


contract NYANSUKE is ERC1155Creator {
    constructor() ERC1155Creator("Gift from a cat", "NYANSUKE") {}
}