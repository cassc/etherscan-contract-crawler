// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Slava3ngl Open Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                                                         //
//      ____  _                    _____             _     //
//     / ___|| | __ ___   ____ _  |___ / _ __   __ _| |    //
//     \___ \| |/ _` \ \ / / _` |   |_ \| '_ \ / _` | |    //
//      ___) | | (_| |\ V / (_| |  ___) | | | | (_| | |    //
//     |____/|_|\__,_| \_/ \__,_| |____/|_| |_|\__, |_|    //
//                                             |___/       //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract S3OE is ERC1155Creator {
    constructor() ERC1155Creator("Slava3ngl Open Editions", "S3OE") {}
}