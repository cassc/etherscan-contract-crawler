// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Great Unreal by Taiyo Onorato & Nico Krebs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    THE GREAT UNREAL                       //
//    BY TAIYO ONORATO & NICO KREBS          //
//    IMAGES © TAIYO ONORATO & NICO KREBS    //
//    ALL RIGHTS RESERVED                    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract UNREAL is ERC721Creator {
    constructor() ERC721Creator("The Great Unreal by Taiyo Onorato & Nico Krebs", "UNREAL") {}
}