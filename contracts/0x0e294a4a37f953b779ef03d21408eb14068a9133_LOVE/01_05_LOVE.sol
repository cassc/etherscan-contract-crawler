// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOVEnfts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//      _                     _       //
//     | |                   | |      //
//     | |__   ___  __ _ _ __| |_     //
//     | '_ \ / _ \/ _` | '__| __|    //
//     | | | |  __/ (_| | |  | |_     //
//     |_| |_|\___|\__,_|_|   \__|    //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract LOVE is ERC721Creator {
    constructor() ERC721Creator("LOVEnfts", "LOVE") {}
}