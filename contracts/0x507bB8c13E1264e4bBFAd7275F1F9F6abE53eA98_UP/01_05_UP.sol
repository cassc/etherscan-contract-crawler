// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UPAPA
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//     _  __ ____    _      ____  ____     //
//    / |/ //  _ \  / \  /|/ ___\/  _ \    //
//    |   / | / \|  | |\ |||    \| / \|    //
//    |   \ | |-||  | | \||\___ || |-||    //
//    \_|\_\\_/ \|  \_/  \|\____/\_/ \|    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract UP is ERC1155Creator {
    constructor() ERC1155Creator("UPAPA", "UP") {}
}