// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stalmi 500 followers celebration
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//      _________ __         .__          .__      //
//     /   _____//  |______  |  |   _____ |__|     //
//     \_____  \\   __\__  \ |  |  /     \|  |     //
//     /        \|  |  / __ \|  |_|  Y Y  \  |     //
//    /_______  /|__| (____  /____/__|_|  /__|     //
//            \/           \/           \/         //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract Stlm1 is ERC1155Creator {
    constructor() ERC1155Creator("Stalmi 500 followers celebration", "Stlm1") {}
}