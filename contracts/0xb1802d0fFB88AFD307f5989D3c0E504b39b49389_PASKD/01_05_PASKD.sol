// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PASK Doodles
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//     _______  _______  _______  ___   _     //
//    |       ||   _   ||       ||   | | |    //
//    |    _  ||  |_|  ||  _____||   |_| |    //
//    |   |_| ||       || |_____ |      _|    //
//    |    ___||       ||_____  ||     |_     //
//    |   |    |   _   | _____| ||    _  |    //
//    |___|    |__| |__||_______||___| |_|    //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract PASKD is ERC1155Creator {
    constructor() ERC1155Creator("PASK Doodles", "PASKD") {}
}