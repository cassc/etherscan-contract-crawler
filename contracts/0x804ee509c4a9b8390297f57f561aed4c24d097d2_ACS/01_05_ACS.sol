// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Astral Circus
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//                        _____  _____               //
//          /\   / ____|/ ____|                      //
//         /  \ | |    | (___                        //
//        / /\ \| |     \___ \                       //
//       / ____ \ |____ ____) |                      //
//      /_/    \_\_____|_____/                       //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract ACS is ERC1155Creator {
    constructor() ERC1155Creator("Astral Circus", "ACS") {}
}