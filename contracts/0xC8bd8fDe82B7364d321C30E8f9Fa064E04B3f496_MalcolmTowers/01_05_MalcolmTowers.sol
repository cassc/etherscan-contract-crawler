// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Malcolm Towers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//      ______      _____  __           //
//     /      \    /     |/  |          //
//    /$$$$$$  |   $$$$$ |$$ |          //
//    $$ \__$$/       $$ |$$ |          //
//    $$      \  __   $$ |$$ |          //
//     $$$$$$  |/  |  $$ |$$ |          //
//    /  \__$$ |$$ \__$$ |$$ |_____     //
//    $$    $$/ $$    $$/ $$       |    //
//     $$$$$$/   $$$$$$/  $$$$$$$$/     //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract MalcolmTowers is ERC721Creator {
    constructor() ERC721Creator("Malcolm Towers", "MalcolmTowers") {}
}