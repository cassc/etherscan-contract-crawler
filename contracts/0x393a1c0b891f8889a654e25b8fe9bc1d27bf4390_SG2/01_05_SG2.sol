// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Senile Gadgetworks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                                                                           //
//     __  ___          ___    __      __  __  ______    __  __      __      //
//    /__`|__ |\ |||   |__    / _` /\ |  \/ _`|__  ||  |/  \|__)|__//__`     //
//    .__/|___| \|||___|___   \__>/~~\|__/\__>|___ ||/\|\__/|  \|  \.__/     //
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract SG2 is ERC1155Creator {
    constructor() ERC1155Creator("Senile Gadgetworks", "SG2") {}
}