// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AfroViking
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//         _     __        __     ___ _    _                 //
//        / \   / _|_ __ __\ \   / (_) | _(_)_ __   __ _     //
//       / _ \ | |_| '__/ _ \ \ / /| | |/ / | '_ \ / _` |    //
//      / ___ \|  _| | | (_) \ V / | |   <| | | | | (_| |    //
//     /_/   \_\_| |_|  \___/ \_/  |_|_|\_\_|_| |_|\__, |    //
//                                                 |___/     //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract afro is ERC721Creator {
    constructor() ERC721Creator("AfroViking", "afro") {}
}