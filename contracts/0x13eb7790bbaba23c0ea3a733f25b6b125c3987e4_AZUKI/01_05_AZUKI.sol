// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Azuki #2741
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    f    //
//         //
//         //
/////////////


contract AZUKI is ERC721Creator {
    constructor() ERC721Creator("Azuki #2741", "AZUKI") {}
}