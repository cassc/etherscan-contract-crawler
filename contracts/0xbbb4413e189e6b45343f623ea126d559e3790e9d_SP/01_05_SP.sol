// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sad Princesses
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//     .-.                 .    .--.                 .      //
//    (   )               _|_   |   )       o       _|_     //
//     `-.  .-. .-..--..-. |    |--'.--..-. . .-. .-.|      //
//    (   )(.-'(   |  (.-' |    |   |  (   )|(.-'(   |      //
//     `-'  `--'`-''   `--'`-'  '   '   `-' | `--'`-'`-'    //
//                                          ;               //
//                                       `-'                //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract SP is ERC721Creator {
    constructor() ERC721Creator("Sad Princesses", "SP") {}
}