// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jgooopt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    NFT/illust artist    //
//                         //
//                         //
/////////////////////////////


contract JG is ERC721Creator {
    constructor() ERC721Creator("Jgooopt", "JG") {}
}