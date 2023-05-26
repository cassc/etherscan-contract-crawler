// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PSYCHOE2023
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//    █ ▄▄     ▄▄▄▄▄   ▀▄    ▄ ▄█▄     ▄  █     //
//    █   █   █     ▀▄   █  █  █▀ ▀▄  █   █     //
//    █▀▀▀  ▄  ▀▀▀▀▄      ▀█   █   ▀  ██▀▀█     //
//    █      ▀▄▄▄▄▀       █    █▄  ▄▀ █   █     //
//     █                ▄▀     ▀███▀     █      //
//      ▀                               ▀       //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract PSYCH is ERC1155Creator {
    constructor() ERC1155Creator("PSYCHOE2023", "PSYCH") {}
}