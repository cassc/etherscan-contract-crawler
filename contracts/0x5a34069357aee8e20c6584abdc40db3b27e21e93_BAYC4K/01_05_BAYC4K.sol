// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bored Ape Yacht Club 4K
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//      ____      __     _______     //
//     |  _ \   /\\ \   / / ____|    //
//     | |_) | /  \\ \_/ / |         //
//     |  _ < / /\ \\   /| |         //
//     | |_) / ____ \| | | |____     //
//     |____/_/    \_\_|  \_____|    //
//                                   //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract BAYC4K is ERC721Creator {
    constructor() ERC721Creator("Bored Ape Yacht Club 4K", "BAYC4K") {}
}