// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Message From Etheral
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                            //
//                                                                                                                            //
//    88888888888  88                        88  88888888888         88                                               88      //
//    88           ""                        88  88           ,d     88                                               88      //
//    88                                     88  88           88     88                                               88      //
//    88aaaaa      88  8b,dPPYba,    ,adPPYb,88  88aaaaa    MM88MMM  88,dPPYba,    ,adPPYba,  8b,dPPYba,  ,adPPYYba,  88      //
//    88"""""      88  88P'   `"8a  a8"    `Y88  88"""""      88     88P'    "8a  a8P_____88  88P'   "Y8  ""     `Y8  88      //
//    88           88  88       88  8b       88  88           88     88       88  8PP"""""""  88          ,adPPPPP88  88      //
//    88           88  88       88  "8a,   ,d88  88           88,    88       88  "8b,   ,aa  88          88,    ,88  88      //
//    88           88  88       88   `"8bbdP"Y8  88888888888  "Y888  88       88   `"Ybbd8"'  88          `"8bbdP"Y8  88      //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FindEtheral is ERC1155Creator {
    constructor() ERC1155Creator("Message From Etheral", "FindEtheral") {}
}