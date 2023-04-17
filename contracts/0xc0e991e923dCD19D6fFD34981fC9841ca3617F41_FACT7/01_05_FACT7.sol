// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 7 Factorial
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    |||||||    //
//    |||||||    //
//    |||||||    //
//    |||||||    //
//    |||||||    //
//               //
//               //
///////////////////


contract FACT7 is ERC1155Creator {
    constructor() ERC1155Creator("7 Factorial", "FACT7") {}
}