// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minimalist Dreamscapes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//     ______   ______ _______ _______ _______ _______ _______ _______  _____  _______    //
//     |     \ |_____/ |______ |_____| |  |  | |______ |       |_____| |_____] |______    //
//     |_____/ |    \_ |______ |     | |  |  | ______| |_____  |     | |       |______    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract DreamScapes is ERC1155Creator {
    constructor() ERC1155Creator("Minimalist Dreamscapes", "DreamScapes") {}
}