// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Crown
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//    ___       ___  __   __   __                //
//     |  |__| |__  /  ` |__) /  \ |  | |\ |     //
//     |  |  | |___ \__, |  \ \__/ |/\| | \|     //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract TC is ERC1155Creator {
    constructor() ERC1155Creator("The Crown", "TC") {}
}