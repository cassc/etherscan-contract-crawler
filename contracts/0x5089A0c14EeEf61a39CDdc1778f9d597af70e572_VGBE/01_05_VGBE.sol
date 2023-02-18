// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vlada Glinskaya Bidders  Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//                          __     __   ______               //
//    /  |   /  | /      \ /       \ /        |              //
//    $$ |   $$ |/$$$$$$  |$$$$$$$  |$$$$$$$$/               //
//    $$ |   $$ |$$ | _$$/ $$ |__$$ |$$ |__                  //
//    $$  \ /$$/ $$ |/    |$$    $$< $$    |                 //
//     $$  /$$/  $$ |$$$$ |$$$$$$$  |$$$$$/                  //
//      $$ $$/   $$ \__$$ |$$ |__$$ |$$ |_____               //
//       $$$/    $$    $$/ $$    $$/ $$       |              //
//        $/      $$$$$$/  $$$$$$$/  $$$$$$$$/               //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract VGBE is ERC1155Creator {
    constructor() ERC1155Creator("Vlada Glinskaya Bidders  Editions", "VGBE") {}
}