// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: You'll Never Get This
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     __   __  __    _  _______  _______     //
//    |  | |  ||  |  | ||       ||       |    //
//    |  |_|  ||   |_| ||    ___||_     _|    //
//    |       ||       ||   | __   |   |      //
//    |_     _||  _    ||   ||  |  |   |      //
//      |   |  | | |   ||   |_| |  |   |      //
//      |___|  |_|  |__||_______|  |___|      //
//                                            //
//                                            //
////////////////////////////////////////////////


contract YNGT is ERC1155Creator {
    constructor() ERC1155Creator("You'll Never Get This", "YNGT") {}
}