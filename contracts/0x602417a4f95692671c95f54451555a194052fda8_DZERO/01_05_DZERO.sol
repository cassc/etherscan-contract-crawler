// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Division Zero
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Division Zero    //
//                     //
//                     //
/////////////////////////


contract DZERO is ERC721Creator {
    constructor() ERC721Creator("Division Zero", "DZERO") {}
}