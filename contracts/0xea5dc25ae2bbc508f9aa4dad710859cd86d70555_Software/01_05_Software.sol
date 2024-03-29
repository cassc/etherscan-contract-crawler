// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Software
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//     ______     ______     ______   ______   __     __     ______     ______     ______        //
//    /\  ___\   /\  __ \   /\  ___\ /\__  _\ /\ \  _ \ \   /\  __ \   /\  == \   /\  ___\       //
//    \ \___  \  \ \ \/\ \  \ \  __\ \/_/\ \/ \ \ \/ ".\ \  \ \  __ \  \ \  __<   \ \  __\       //
//     \/\_____\  \ \_____\  \ \_\      \ \_\  \ \__/".~\_\  \ \_\ \_\  \ \_\ \_\  \ \_____\     //
//      \/_____/   \/_____/   \/_/       \/_/   \/_/   \/_/   \/_/\/_/   \/_/ /_/   \/_____/     //
//                                                                                               //
//    softwareboy.studio                                                                         //
//                                                                                               //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract Software is ERC721Creator {
    constructor() ERC721Creator("Software", "Software") {}
}