// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lines
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//      _    ___ _  _ ___ ___     //
//     | |  |_ _| \| | __/ __|    //
//     | |__ | || .` | _|\__ \    //
//     |____|___|_|\_|___|___/    //
//                                //
//                                //
////////////////////////////////////


contract LNS is ERC1155Creator {
    constructor() ERC1155Creator("Lines", "LNS") {}
}