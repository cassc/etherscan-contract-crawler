// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lola Dupre
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    (  )  (  _ \     //
//     )(__  )(_) )    //
//    (____)(____/     //
//                     //
//                     //
/////////////////////////


contract LD is ERC721Creator {
    constructor() ERC721Creator("Lola Dupre", "LD") {}
}