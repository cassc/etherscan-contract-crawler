// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Leisha OE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//                                                //
//     __        _     _          _____ _____     //
//    |  |   ___|_|___| |_ ___   |     |   __|    //
//    |  |__| -_| |_ -|   | .'|  |  |  |   __|    //
//    |_____|___|_|___|_|_|__,|  |_____|_____|    //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract LOE is ERC1155Creator {
    constructor() ERC1155Creator("Leisha OE", "LOE") {}
}