// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TheBlackAaron's Rent
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//          ___           ___           ___                                //
//         /\  \         /\__\         /\  \                               //
//        /::\  \       /:/ _/_        \:\  \         ___                  //
//       /:/\:\__\     /:/ /\__\        \:\  \       /\__\                 //
//      /:/ /:/  /    /:/ /:/ _/_   _____\:\  \     /:/  /                 //
//     /:/_/:/__/___ /:/_/:/ /\__\ /::::::::\__\   /:/__/                  //
//     \:\/:::::/  / \:\/:/ /:/  / \:\~~\~~\/__/  /::\  \                  //
//      \::/~~/~~~~   \::/_/:/  /   \:\  \       /:/\:\  \                 //
//       \:\~~\        \:\/:/  /     \:\  \      \/__\:\  \                //
//        \:\__\        \::/  /       \:\__\          \:\__\               //
//         \/__/         \/__/         \/__/           \/__/               //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract TBAR is ERC1155Creator {
    constructor() ERC1155Creator("TheBlackAaron's Rent", "TBAR") {}
}