// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MNiML vXYZ
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                       _)             |            \ \  / \ \   / __  /     //
//      __ `__ \   __ \   |  __ `__ \   |     \ \   / \  /   \   /     /      //
//      |   |   |  |   |  |  |   |   |  |      \ \ /     \      |     /       //
//     _|  _|  _| _|  _| _| _|  _|  _| _|       \_/   _/\_\    _|   ____|     //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract vXYZ is ERC721Creator {
    constructor() ERC721Creator("MNiML vXYZ", "vXYZ") {}
}