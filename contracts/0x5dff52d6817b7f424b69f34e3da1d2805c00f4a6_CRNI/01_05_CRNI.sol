// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Carnie AI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     ____   ____  _____  __  _  _  ____     //
//    / (__` / () \ | () )|  \| || || ===|    //
//    \____)/__/\__\|_|\_\|_|\__||_||____|    //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract CRNI is ERC721Creator {
    constructor() ERC721Creator("Carnie AI", "CRNI") {}
}