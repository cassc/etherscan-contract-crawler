// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kotest5
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    　 ∧∧         //
//    　(,,ﾟДﾟ)　    //
//                 //
//                 //
/////////////////////


contract nk5 is ERC721Creator {
    constructor() ERC721Creator("kotest5", "nk5") {}
}