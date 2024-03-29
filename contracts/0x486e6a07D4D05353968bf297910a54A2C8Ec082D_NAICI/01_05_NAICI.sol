// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOT AI CITIES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//    $$\   $$\  $$$$$$\ $$$$$$$$\        $$$$$$\  $$$$$$\        $$$$$$\  $$$$$$\ $$$$$$$$\ $$$$$$\ $$$$$$$$\  $$$$$$\      //
//    $$$\  $$ |$$  __$$\\__$$  __|      $$  __$$\ \_$$  _|      $$  __$$\ \_$$  _|\__$$  __|\_$$  _|$$  _____|$$  __$$\     //
//    $$$$\ $$ |$$ /  $$ |  $$ |         $$ /  $$ |  $$ |        $$ /  \__|  $$ |     $$ |     $$ |  $$ |      $$ /  \__|    //
//    $$ $$\$$ |$$ |  $$ |  $$ |         $$$$$$$$ |  $$ |        $$ |        $$ |     $$ |     $$ |  $$$$$\    \$$$$$$\      //
//    $$ \$$$$ |$$ |  $$ |  $$ |         $$  __$$ |  $$ |        $$ |        $$ |     $$ |     $$ |  $$  __|    \____$$\     //
//    $$ |\$$$ |$$ |  $$ |  $$ |         $$ |  $$ |  $$ |        $$ |  $$\   $$ |     $$ |     $$ |  $$ |      $$\   $$ |    //
//    $$ | \$$ | $$$$$$  |  $$ |         $$ |  $$ |$$$$$$\       \$$$$$$  |$$$$$$\    $$ |   $$$$$$\ $$$$$$$$\ \$$$$$$  |    //
//    \__|  \__| \______/   \__|         \__|  \__|\______|       \______/ \______|   \__|   \______|\________| \______/     //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NAICI is ERC721Creator {
    constructor() ERC721Creator("NOT AI CITIES", "NAICI") {}
}