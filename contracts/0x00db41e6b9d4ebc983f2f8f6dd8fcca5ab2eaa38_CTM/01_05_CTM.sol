// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Call to Meme
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//                       //
//                       //
//    __________.___     //
//    \______   \   |    //
//     |     ___/   |    //
//     |    |   |   |    //
//     |____|   |___|    //
//                       //
//                       //
///////////////////////////


contract CTM is ERC1155Creator {
    constructor() ERC1155Creator("Call to Meme", "CTM") {}
}