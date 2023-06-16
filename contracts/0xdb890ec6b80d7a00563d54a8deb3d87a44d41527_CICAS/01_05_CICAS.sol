// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: chaos becomes inverted, not averted by Cole Sternberg
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//             .                                   //
//             |                                   //
//     .-. .-. |  .-.                              //
//    (   (   )| (.-'                              //
//     `-' `-' `- `--'                             //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//         .                .                      //
//        _|_               |                      //
//    .--. |   .-. .--..--. |.-.  .-. .--. .-..    //
//    `--. |  (.-' |   |  | |   )(.-' |   (   |    //
//    `--' `-' `--''   '  `-'`-'  `--''    `-`|    //
//                                         ._.'    //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract CICAS is ERC721Creator {
    constructor() ERC721Creator("chaos becomes inverted, not averted by Cole Sternberg", "CICAS") {}
}