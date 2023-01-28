// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Confetti Splash
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//    `...     `..`..     `..    //
//    `. `..   `..`..     `..    //
//    `.. `..  `..`..     `..    //
//    `..  `.. `..`...... `..    //
//    `..   `. `..`..     `..    //
//    `..    `. ..`..     `..    //
//    `..      `..`..     `..    //
//                               //
//                               //
//                               //
//                               //
//                               //
//                               //
//                               //
//                               //
//                               //
//                               //
//                               //
//                               //
///////////////////////////////////


contract CS is ERC721Creator {
    constructor() ERC721Creator("Confetti Splash", "CS") {}
}