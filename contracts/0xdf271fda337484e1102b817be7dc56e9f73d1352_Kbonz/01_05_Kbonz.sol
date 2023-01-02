// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KBonzinLA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    KBONZ    //
//             //
//             //
/////////////////


contract Kbonz is ERC721Creator {
    constructor() ERC721Creator("KBonzinLA", "Kbonz") {}
}