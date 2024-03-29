// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shakes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//          ___           ___           ___           ___           ___           ___         //
//         /\  \         /\__\         /\  \         /\__\         /\  \         /\  \        //
//        /::\  \       /:/  /        /::\  \       /:/  /        /::\  \       /::\  \       //
//       /:/\ \  \     /:/__/        /:/\:\  \     /:/__/        /:/\:\  \     /:/\ \  \      //
//      _\:\~\ \  \   /::\  \ ___   /::\~\:\  \   /::\__\____   /::\~\:\  \   _\:\~\ \  \     //
//     /\ \:\ \ \__\ /:/\:\  /\__\ /:/\:\ \:\__\ /:/\:::::\__\ /:/\:\ \:\__\ /\ \:\ \ \__\    //
//     \:\ \:\ \/__/ \/__\:\/:/  / \/__\:\/:/  / \/_|:|~~|~    \:\~\:\ \/__/ \:\ \:\ \/__/    //
//      \:\ \:\__\        \::/  /       \::/  /     |:|  |      \:\ \:\__\    \:\ \:\__\      //
//       \:\/:/  /        /:/  /        /:/  /      |:|  |       \:\ \/__/     \:\/:/  /      //
//        \::/  /        /:/  /        /:/  /       |:|  |        \:\__\        \::/  /       //
//         \/__/         \/__/         \/__/         \|__|         \/__/         \/__/        //
//                                                                                            //
//          ___           ___           ___           ___           ___           ___         //
//         /\__\         /\  \         /\  \         /|  |         /\__\         /\__\        //
//        /:/ _/_        \:\  \       /::\  \       |:|  |        /:/ _/_       /:/ _/_       //
//       /:/ /\  \        \:\  \     /:/\:\  \      |:|  |       /:/ /\__\     /:/ /\  \      //
//      /:/ /::\  \   ___ /::\  \   /:/ /::\  \   __|:|  |      /:/ /:/ _/_   /:/ /::\  \     //
//     /:/_/:/\:\__\ /\  /:/\:\__\ /:/_/:/\:\__\ /\ |:|__|____ /:/_/:/ /\__\ /:/_/:/\:\__\    //
//     \:\/:/ /:/  / \:\/:/  \/__/ \:\/:/  \/__/ \:\/:::::/__/ \:\/:/ /:/  / \:\/:/ /:/  /    //
//      \::/ /:/  /   \::/__/       \::/__/       \::/~~/~      \::/_/:/  /   \::/ /:/  /     //
//       \/_/:/  /     \:\  \        \:\  \        \:\~~\        \:\/:/  /     \/_/:/  /      //
//         /:/  /       \:\__\        \:\__\        \:\__\        \::/  /        /:/  /       //
//         \/__/         \/__/         \/__/         \/__/         \/__/         \/__/        //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract SHAKES is ERC721Creator {
    constructor() ERC721Creator("Shakes", "SHAKES") {}
}