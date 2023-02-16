// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: h3xum fake memes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//    ,--.     ,----.                                  //
//    |  ,---. '.-.  |,--.  ,--.,--.,--.,--,--,--.     //
//    |  .-.  |  .' <  \  `'  / |  ||  ||        |     //
//    |  | |  |/'-'  | /  /.  \ '  ''  '|  |  |  |     //
//    `--' `--'`----' '--'  '--' `----' `--`--`--'     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract h3xfm is ERC1155Creator {
    constructor() ERC1155Creator("h3xum fake memes", "h3xfm") {}
}