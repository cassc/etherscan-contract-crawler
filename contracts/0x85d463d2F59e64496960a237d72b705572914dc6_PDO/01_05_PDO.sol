// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepes Day Off
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    ♡    //
//         //
//         //
/////////////


contract PDO is ERC721Creator {
    constructor() ERC721Creator("Pepes Day Off", "PDO") {}
}