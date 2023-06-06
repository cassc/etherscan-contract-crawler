// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: untitled season editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//        ___       ___       ___       //
//       /\__\     /\  \     /\  \      //
//      /:/ _/_   /::\  \   /::\  \     //
//     /:/_/\__\ /\:\:\__\ /::\:\__\    //
//     \:\/:/  / \:\:\/__/ \:\:\/  /    //
//      \::/  /   \::/  /   \:\/  /     //
//       \/__/     \/__/     \/__/      //
//                                      //
//                                      //
//////////////////////////////////////////


contract USE is ERC1155Creator {
    constructor() ERC1155Creator("untitled season editions", "USE") {}
}