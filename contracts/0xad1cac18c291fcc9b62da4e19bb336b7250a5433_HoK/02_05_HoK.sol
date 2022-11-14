// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Head of Knights
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//            _____ _______ _______        _______ _     _ _______ _______    //
//     |        |      |       |    |      |______ |_____| |_____|    |       //
//     |_____ __|__    |       |    |_____ |______ |     | |     |    |       //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract HoK is ERC721Creator {
    constructor() ERC721Creator("The Head of Knights", "HoK") {}
}