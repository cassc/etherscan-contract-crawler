// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 2022 Collectors' Edition by A Big Blue Bird
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//          _           ___    __                 ___    __                           ___    __               _       //
//         /.\         F _ ",  LJ    ___ _       F _ ",  LJ   _    _     ____        F _ ",  LJ   _ ___    ___FJ      //
//        //_\\       J `-'(|       F __` L     J `-'(|  FJ  J |  | L   F __ J      J `-'(|      J '__ ", F __  L     //
//       / ___ \      | ,--.\  FJ  | |--| |     | ,--.\ J  L | |  | |  | _____J     | ,--.\  FJ  | |__|-J| |--| |     //
//      / L___J \     F L__J \J  L F L__J J     F L__J \J  L F L__J J  F L___--.    F L__J \J  L F L  `-'F L__J J     //
//     J__L   J__L   J_______JJ__L )-____  L   J_______JJ__LJ\____,__LJ\______/F   J_______JJ__LJ__L    J\____,__L    //
//     |__L   J__|   |_______F|__|J\______/F   |_______F|__| J____,__F J______F    |_______F|__||__L     J____,__F    //
//                                 J______F                                                                           //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ABBB22 is ERC721Creator {
    constructor() ERC721Creator("2022 Collectors' Edition by A Big Blue Bird", "ABBB22") {}
}