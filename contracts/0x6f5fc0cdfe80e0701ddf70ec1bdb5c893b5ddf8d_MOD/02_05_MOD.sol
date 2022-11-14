// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ExperiMod
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//        ___       ___       ___       //
//       /\__\     /\  \     /\  \      //
//      /::L_L_   /::\  \   /::\  \     //
//     /:/L:\__\ /:/\:\__\ /:/\:\__\    //
//     \/_/:/  / \:\/:/  / \:\/:/  /    //
//       /:/  /   \::/  /   \::/  /     //
//       \/__/     \/__/     \/__/      //
//                                      //
//                                      //
//////////////////////////////////////////


contract MOD is ERC721Creator {
    constructor() ERC721Creator("ExperiMod", "MOD") {}
}