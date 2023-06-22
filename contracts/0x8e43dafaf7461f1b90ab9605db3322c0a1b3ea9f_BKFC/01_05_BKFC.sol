// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Function Compositions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//     _______  ___   _  _______  _______     //
//    |  _    ||   | | ||       ||       |    //
//    | |_|   ||   |_| ||    ___||       |    //
//    |       ||      _||   |___ |       |    //
//    |  _   | |     |_ |    ___||      _|    //
//    | |_|   ||    _  ||   |    |     |_     //
//    |_______||___| |_||___|    |_______|    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract BKFC is ERC721Creator {
    constructor() ERC721Creator("Function Compositions", "BKFC") {}
}