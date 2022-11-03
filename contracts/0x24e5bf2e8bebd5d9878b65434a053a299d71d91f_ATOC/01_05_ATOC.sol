// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Touch Of Culture
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//         //
//         //
//         //
/////////////


contract ATOC is ERC721Creator {
    constructor() ERC721Creator("A Touch Of Culture", "ATOC") {}
}