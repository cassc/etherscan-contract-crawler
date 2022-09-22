// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beyond the Borders
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//                                           //
//    88888888ba            88888888ba       //
//    88      "8b    ,d     88      "8b      //
//    88      ,8P    88     88      ,8P      //
//    88aaaaaa8P'  MM88MMM  88aaaaaa8P'      //
//    88""""""8b,    88     88""""""8b,      //
//    88      `8b    88     88      `8b      //
//    88      a8P    88,    88      a8P      //
//    88888888P"     "Y888  88888888P"       //
//                                           //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract BtB is ERC721Creator {
    constructor() ERC721Creator("Beyond the Borders", "BtB") {}
}