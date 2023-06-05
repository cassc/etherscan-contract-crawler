// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Silk Way
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//                                            //
//     .-.     . .      .  .   .  .           //
//    (   ) o  | |       \  \ /  /            //
//     `-.  .  | |.-.     \  \  /.-.  .  .    //
//    (   ) |  | |-.'      \/ \/(   ) |  |    //
//     `-'-' `-`-'  `-      ' '  `-'`-`--|    //
//                                       ;    //
//                                    `-'     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract SILK is ERC721Creator {
    constructor() ERC721Creator("Silk Way", "SILK") {}
}