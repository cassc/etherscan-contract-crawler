// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spread The Love
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    This is maloriginals.eth open edition (OE) contract; Spread The Love.     //
//                                                                              //
//                                                                              //
//                             ██████████████████                               //
//                           ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██                             //
//                         ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██                           //
//                       ██▓▓▓▓▓▓░░░░░░░░░░░░░░▓▓▓▓▓▓██                         //
//                       ██▓▓▓▓░░░░░░░░░░░░░░░░░░▓▓▓▓██                         //
//                   ████▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓████                     //
//                 ██▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓██                   //
//                 ██▓▓░░▓▓░░░░████░░░░░░░░░░████░░░░▓▓░░▓▓██                   //
//                 ██▓▓░░▓▓░░██░░░░██░░░░░░██░░░░██░░▓▓░░▓▓██                   //
//                   ██████▓▓░░░░░░░░░░░░░░░░░░░░░░▓▓██████                     //
//                       ██▓▓░░░░░░░░░░░░░░░░░░░░░░▓▓██                         //
//                         ██▓▓░░░░░░░░░░░░░░░░░░▓▓██                           //
//           ██▓▓██          ██▓▓░░░░░░░░░░░░░░▓▓████                           //
//         ██▓▓░░▓▓██          ██▓▓▓▓░░░░░░▓▓▓▓██                               //
//         ▓▓░░    ▓▓██      ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██                             //
//         ██▓▓    ██▓▓██  ██▓▓▓▓▓▓░░░░░░░░░░▓▓▓▓▓▓██                           //
//           ██▓▓    ██▓▓  ██▓▓▓▓▓▓░░░░░░░░░░▓▓▓▓▓▓██                           //
//             ░░▓▓    ▓▓██▓▓▓▓██▓▓▓▓░░░░░░▓▓▓▓██▓▓▓▓██                         //
//             ▓▓██    ████▓▓████▓▓▓▓░░░░░░▓▓▓▓████▓▓██                         //
//                       ██▓▓████▓▓▓▓░░░░░░▓▓▓▓████▓▓██                         //
//                         ██  ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓██  ██                           //
//                             ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓██                               //
//                             ██▓▓▓▓▓▓██▓▓▓▓▓▓██                               //
//                               ██████  ██████                                 //
//                                                                              //
//              ASCII ART CRED: https://textart.sh/topic/monkey                 //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract STL is ERC1155Creator {
    constructor() ERC1155Creator("Spread The Love", "STL") {}
}