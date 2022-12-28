// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: maxwell
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//                               //
//      _ __ ___   __ ___  __    //
//     | '_ ` _ \ / _` \ \/ /    //
//     | | | | | | (_| |>  <     //
//     |_| |_| |_|\__,_/_/\_\    //
//                               //
//                               //
//                               //
//                               //
//                               //
//                               //
///////////////////////////////////


contract max is ERC721Creator {
    constructor() ERC721Creator("maxwell", "max") {}
}