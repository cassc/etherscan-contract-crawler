// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lillet NFT 1st Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//     Created by                                                             //
//      _____            ____                                                 //
//     / ___/__  ___    / __/  _____ ®                                        //
//    / /__/ _ \/ _ \  / _/| |/ / _ \                                         //
//    \___/\___/_//_/ /___/|___/\___/                                         //
//                    www.con-evo.com                                         //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract LAL is ERC721Creator {
    constructor() ERC721Creator("Lillet NFT 1st Edition", "LAL") {}
}