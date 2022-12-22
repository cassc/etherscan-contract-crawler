// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sanaz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//                                    //
//      ___  __ _ _ __   __ _ ____    //
//     / __|/ _` | '_ \ / _` |_  /    //
//     \__ \ (_| | | | | (_| |/ /     //
//     |___/\__,_|_| |_|\__,_/___|    //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract SNZ is ERC721Creator {
    constructor() ERC721Creator("Sanaz", "SNZ") {}
}