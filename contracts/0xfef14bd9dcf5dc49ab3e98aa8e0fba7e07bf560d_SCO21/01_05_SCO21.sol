// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skilux Collection OpenSea 2021
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    .    //
//         //
//         //
/////////////


contract SCO21 is ERC721Creator {
    constructor() ERC721Creator("Skilux Collection OpenSea 2021", "SCO21") {}
}