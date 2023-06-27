// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 全国行タイカレー
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//                                             //
//     .---. __   _  _ .--. _ .--. _   __      //
//    / /'`\|  | | |[ `/'`\| `/'`\| \ [  ]     //
//    | \__. | \_/ |,| |    | |    \ '/ /      //
//    '.___.''.__.'_[___]  [___] [\_:  /       //
//                                \__.'        //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract CURRY is ERC1155Creator {
    constructor() ERC1155Creator(unicode"全国行タイカレー", "CURRY") {}
}