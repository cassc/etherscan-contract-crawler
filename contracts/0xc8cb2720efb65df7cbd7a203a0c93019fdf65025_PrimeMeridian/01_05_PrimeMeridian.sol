// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PrimeMeridian
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//     _     _ _______                _____       _  _  _  _____   ______        ______     //
//     |_____| |______ |      |      |     |      |  |  | |     | |_____/ |      |     \    //
//     |     | |______ |_____ |_____ |_____|      |__|__| |_____| |    \_ |_____ |_____/    //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract PrimeMeridian is ERC721Creator {
    constructor() ERC721Creator("PrimeMeridian", "PrimeMeridian") {}
}