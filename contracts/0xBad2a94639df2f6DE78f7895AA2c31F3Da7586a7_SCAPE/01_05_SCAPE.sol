// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Scapepe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//     _____ _____ _____ _____ _____ _____ _____     //
//    |   __|     |  _  |  _  |   __|  _  |   __|    //
//    |__   |   --|     |   __|   __|   __|   __|    //
//    |_____|_____|__|__|__|  |_____|__|  |_____|    //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract SCAPE is ERC1155Creator {
    constructor() ERC1155Creator("Scapepe", "SCAPE") {}
}