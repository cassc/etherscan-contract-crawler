// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cx Crypto
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//        .___  .___  .___    //
//      __| _/__| _/__| _/    //
//     / __ |/ __ |/ __ |     //
//    / /_/ / /_/ / /_/ |     //
//    \____ \____ \____ |     //
//         \/    \/    \/     //
//                            //
//                            //
//                            //
////////////////////////////////


contract CX is ERC721Creator {
    constructor() ERC721Creator("Cx Crypto", "CX") {}
}