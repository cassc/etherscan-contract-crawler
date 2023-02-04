// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Maria Miller
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//     _____         _        _____ _ _ _             //
//    |     |___ ___|_|___   |     |_| | |___ ___     //
//    | | | | .'|  _| | .'|  | | | | | | | -_|  _|    //
//    |_|_|_|__,|_| |_|__,|  |_|_|_|_|_|_|___|_|      //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract MM is ERC1155Creator {
    constructor() ERC1155Creator("Maria Miller", "MM") {}
}