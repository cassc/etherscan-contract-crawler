// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AZUKl
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    .    //
//         //
//         //
/////////////


contract AZUKI is ERC721Creator {
    constructor() ERC721Creator("AZUKl", "AZUKI") {}
}