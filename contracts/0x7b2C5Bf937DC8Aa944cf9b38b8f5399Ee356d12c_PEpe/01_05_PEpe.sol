// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PePe Manifold
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//     ____   ___  ____   ___            //
//    |    \ /  _]|    \ /  _]           //
//    |  o  )  [_ |  o  )  [_            //
//    |   _/    _]|   _/    _]           //
//    |  | |   [_ |  | |   [_            //
//    |  | |     ||  | |     |           //
//    |__| |_____||__| |_____|           //
//                                       //
//                                       //
///////////////////////////////////////////


contract PEpe is ERC721Creator {
    constructor() ERC721Creator("PePe Manifold", "PEpe") {}
}