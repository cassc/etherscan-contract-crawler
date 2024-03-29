// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UnicornGirlJuJu Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//     _____     _                 _____ _     _    __        __         //
//    |  |  |___|_|___ ___ ___ ___|   __|_|___| |__|  |_ _ __|  |_ _     //
//    |  |  |   | |  _| . |  _|   |  |  | |  _| |  |  | | |  |  | | |    //
//    |_____|_|_|_|___|___|_| |_|_|_____|_|_| |_|_____|___|_____|___|    //
//                                                                       //
//     _____   _ _ _   _                                                 //
//    |   __|_| |_| |_|_|___ ___ ___                                     //
//    |   __| . | |  _| | . |   |_ -|                                    //
//    |_____|___|_|_| |_|___|_|_|___|                                    //
//                                                                       //
//    @unicorngirljuju                                                   //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract UGJJE is ERC1155Creator {
    constructor() ERC1155Creator("UnicornGirlJuJu Editions", "UGJJE") {}
}