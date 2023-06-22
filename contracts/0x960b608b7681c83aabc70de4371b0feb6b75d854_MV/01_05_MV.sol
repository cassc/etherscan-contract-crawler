// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MV
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    ,    //
//         //
//         //
/////////////


contract MV is ERC721Creator {
    constructor() ERC721Creator("MV", "MV") {}
}