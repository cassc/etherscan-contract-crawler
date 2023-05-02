// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SAKRA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    The magic of color.NFT    //
//                              //
//                              //
//////////////////////////////////


contract Goodcolor is ERC721Creator {
    constructor() ERC721Creator("SAKRA", "Goodcolor") {}
}