// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Strange Clouds
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                                                                   //
//        ___       ___       ___       ___       ___       ___       ___            //
//       /\  \     /\  \     /\  \     /\  \     /\__\     /\  \     /\  \           //
//      /::\  \    \:\  \   /::\  \   /::\  \   /:| _|_   /::\  \   /::\  \          //
//     /\:\:\__\   /::\__\ /::\:\__\ /::\:\__\ /::|/\__\ /:/\:\__\ /::\:\__\         //
//     \:\:\/__/  /:/\/__/ \;:::/  / \/\::/  / \/|::/  / \:\:\/__/ \:\:\/  /         //
//      \::/  /   \/__/     |:\/__/    /:/  /    |:/  /   \::/  /   \:\/  /          //
//       \/__/               \|__|     \/__/     \/__/     \/__/     \/__/           //
//        ___       ___       ___       ___       ___       ___                      //
//       /\  \     /\__\     /\  \     /\__\     /\  \     /\  \                     //
//      /::\  \   /:/  /    /::\  \   /:/ _/_   /::\  \   /::\  \                    //
//     /:/\:\__\ /:/__/    /:/\:\__\ /:/_/\__\ /:/\:\__\ /\:\:\__\                   //
//     \:\ \/__/ \:\  \    \:\/:/  / \:\/:/  / \:\/:/  / \:\:\/__/                   //
//      \:\__\    \:\__\    \::/  /   \::/  /   \::/  /   \::/  /                    //
//       \/__/     \/__/     \/__/     \/__/     \/__/     \/__/                     //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract STCL is ERC721Creator {
    constructor() ERC721Creator("Strange Clouds", "STCL") {}
}