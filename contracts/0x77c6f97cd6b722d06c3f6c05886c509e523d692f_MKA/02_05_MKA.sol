// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ataturkcu.eth
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//      __  __ _  __    _        //
//     |  \/  | |/ /   / \       //
//     | |\/| | ' /   / _ \      //
//     | |  | | . \  / ___ \     //
//     |_|  |_|_|\_\/_/   \_\    //
//                               //
//                               //
///////////////////////////////////


contract MKA is ERC721Creator {
    constructor() ERC721Creator("ataturkcu.eth", "MKA") {}
}