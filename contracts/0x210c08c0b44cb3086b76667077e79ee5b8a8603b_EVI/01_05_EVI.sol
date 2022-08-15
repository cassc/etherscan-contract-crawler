// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: peacenik
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                                                                   //
//                                     _ _                           //
//     _ __   ___  __ _  ___ ___ _ __ (_) | __                       //
//    | '_ \ / _ \/ _` |/ __/ _ \ '_ \| | |/ /                       //
//    | |_) |  __/ (_| | (_|  __/ | | | |   <                        //
//    | .__/ \___|\__,_|\___\___|_| |_|_|_|\_\                       //
//    |_|                                                            //
//                                                                   //
//                                                                   //
//        - often a derogatory term,                                 //
//              'a peacenik is a member of the pacifist movement'    //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract EVI is ERC721Creator {
    constructor() ERC721Creator("peacenik", "EVI") {}
}