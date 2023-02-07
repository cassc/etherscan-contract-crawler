// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gully ENT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//     _____ _     _     _    ___  _      //
//    /  __// \ /\/ \   / \   \  \//      //
//    | |  _| | ||| |   | |    \  /       //
//    | |_//| \_/|| |_/\| |_/\ / /        //
//    \____\\____/\____/\____//_/         //
//                                        //
//                                        //
////////////////////////////////////////////


contract GLY is ERC1155Creator {
    constructor() ERC1155Creator("Gully ENT", "GLY") {}
}