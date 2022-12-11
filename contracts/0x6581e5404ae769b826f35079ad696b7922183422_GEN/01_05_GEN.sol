// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ephemera: Genesis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//       __|  __|   \ |  __|   __| _ _|   __|     //
//      (_ |  _|      |  _|  \__ \   |  \__ \     //
//     \___| ___| _|\_| ___| ____/ ___| ____/     //
//                                                //
//     ______________________________________     //
//                                                //
//     a triptych series by Ozan Mutlu Dursun     //
//                      2022                      //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract GEN is ERC721Creator {
    constructor() ERC721Creator("Ephemera: Genesis", "GEN") {}
}