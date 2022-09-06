// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Girl with the Dragon Tattoo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//     ______   ______ _______  ______  _____  __   _          //
//     |     \ |_____/ |_____| |  ____ |     | | \  |          //
//     |_____/ |    \_ |     | |_____| |_____| |  \_|          //
//                                                             //
//     _______ _______ _______ _______  _____   _____          //
//        |    |_____|    |       |    |     | |     |         //
//        |    |     |    |       |    |_____| |_____|         //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract LJGD is ERC721Creator {
    constructor() ERC721Creator("The Girl with the Dragon Tattoo", "LJGD") {}
}