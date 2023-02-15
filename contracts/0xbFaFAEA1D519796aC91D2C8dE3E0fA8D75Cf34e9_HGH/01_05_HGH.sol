// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hayabusa Girls Honmei
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    ♡    //
//         //
//         //
/////////////


contract HGH is ERC721Creator {
    constructor() ERC721Creator("Hayabusa Girls Honmei", "HGH") {}
}