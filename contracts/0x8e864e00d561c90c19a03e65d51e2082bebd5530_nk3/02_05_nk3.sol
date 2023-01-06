// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nekotest3
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


contract nk3 is ERC721Creator {
    constructor() ERC721Creator("nekotest3", "nk3") {}
}