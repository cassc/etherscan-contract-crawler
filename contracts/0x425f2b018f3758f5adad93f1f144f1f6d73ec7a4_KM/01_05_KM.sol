// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: k$ nft
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//      _  __    ||_       //
//     | |/ /   (_-<       //
//     | ' <    / _/       //
//     |_|\_\   _||__      //
//    _|"""""|_|"""""|     //
//    "`-0-0-'"`-0-0-'     //
//                         //
//                         //
/////////////////////////////


contract KM is ERC721Creator {
    constructor() ERC721Creator("k$ nft", "KM") {}
}