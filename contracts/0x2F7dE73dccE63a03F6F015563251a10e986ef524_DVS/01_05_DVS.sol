// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DeviousPeoples
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    ■    //
//         //
//         //
/////////////


contract DVS is ERC721Creator {
    constructor() ERC721Creator("DeviousPeoples", "DVS") {}
}