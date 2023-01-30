// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BanksyXvanGogh Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
//     _____         _           __ __             _____         _       //
//    | __  |___ ___| |_ ___ _ _|  |  |_ _ ___ ___|   __|___ ___| |_     //
//    | __ -| .'|   | '_|_ -| | |-   -| | | .'|   |  |  | . | . |   |    //
//    |_____|__,|_|_|_,_|___|_  |__|__|\_/|__,|_|_|_____|___|_  |_|_|    //
//                          |___|                           |___|        //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract BxvG is ERC721Creator {
    constructor() ERC721Creator("BanksyXvanGogh Editions", "BxvG") {}
}