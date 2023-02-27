// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Strokes Of Genius
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//      _________ __                 __               //
//     /   _____//  |________  ____ |  | __ ____      //
//     \_____  \\   __\_  __ \/  _ \|  |/ // __ \     //
//     /        \|  |  |  | \(  <_> )    <\  ___/     //
//    /_______  /|__|  |__|   \____/|__|_ \\___  >    //
//            \/                         \/    \/     //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract Stroke is ERC721Creator {
    constructor() ERC721Creator("Strokes Of Genius", "Stroke") {}
}