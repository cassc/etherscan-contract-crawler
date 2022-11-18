// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flowers 4 Men
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//       .---..                            .  .   .    .                      //
//       |    |                            |  |   |\  /|                      //
//       |--- | .-..  .    ._.-. .--..--.  '--|-  | \/ | .-. .--.             //
//       |    |(   )\  \  / (.-' |   `--.     |   |    |(.-' |  |             //
//       '    `-`-'  `' `'   `--''   `--'     '   '    ' `--''  `-            //
//       .          .---.    . .                                              //
//       |          |        | |                                              //
//       |.-. .  .  |--- .--.| | .-.                                          //
//       |   )|  |  |    `--.| |(.-'                                          //
//       '`-' `--|  '---'`--'`-`-`--'                                         //
//               ;                                                            //
//             `-'                                                            //
//                                                                            //
//       Flowers have historically given meaning to things that               //
//       cannot be expressed out loud.                                        //
//       They represent a freedom of communication against                    //
//       societal norms and taboos.                                           //
//       Flowers 4 Men is a celebration of men who dare to                    //
//       embrace the strength of softness and the feminine.                   //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract F4M is ERC721Creator {
    constructor() ERC721Creator("Flowers 4 Men", "F4M") {}
}