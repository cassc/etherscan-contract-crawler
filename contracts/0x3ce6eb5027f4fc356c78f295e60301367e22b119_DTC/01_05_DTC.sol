// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Degen Tattoo Club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//     _______   ________  ______      //
//    /       \ /        |/      \     //
//    $$$$$$$  |$$$$$$$$//$$$$$$  |    //
//    $$ |  $$ |   $$ |  $$ |  $$/     //
//    $$ |  $$ |   $$ |  $$ |          //
//    $$ |  $$ |   $$ |  $$ |   __     //
//    $$ |__$$ |   $$ |  $$ \__/  |    //
//    $$    $$/    $$ |  $$    $$/     //
//    $$$$$$$/     $$/    $$$$$$/      //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract DTC is ERC721Creator {
    constructor() ERC721Creator("Degen Tattoo Club", "DTC") {}
}