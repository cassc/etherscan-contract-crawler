// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nekotest4
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


contract nk4 is ERC721Creator {
    constructor() ERC721Creator("nekotest4", "nk4") {}
}