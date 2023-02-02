// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VALGOBBLERS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//      /_/\     //
//     (^ .^)    //
//     c " c     //
//     \ - /     //
//               //
//               //
///////////////////


contract VGB is ERC721Creator {
    constructor() ERC721Creator("VALGOBBLERS", "VGB") {}
}