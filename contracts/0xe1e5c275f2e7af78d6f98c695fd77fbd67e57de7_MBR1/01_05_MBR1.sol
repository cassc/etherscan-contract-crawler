// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MINTBOAR
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//            .__        __ ___.                           //
//      _____ |__| _____/  |\_ |__   _________ _______     //
//     /     \|  |/    \   __\ __ \ /  _ \__  \\_  __ \    //
//    |  Y Y  \  |   |  \  | | \_\ (  <_> ) __ \|  | \/    //
//    |__|_|  /__|___|  /__| |___  /\____(____  /__|       //
//          \/        \/         \/           \/           //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract MBR1 is ERC721Creator {
    constructor() ERC721Creator("MINTBOAR", "MBR1") {}
}