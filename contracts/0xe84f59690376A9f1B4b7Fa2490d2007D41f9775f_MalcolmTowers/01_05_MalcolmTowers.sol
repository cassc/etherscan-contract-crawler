// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions By Malcolm Towers
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//       ______      _____  __           //
//     /      \    /     |/  |           //
//    /$$$$$$  |   $$$$$ |$$ |           //
//    $$ \__$$/       $$ |$$ |           //
//    $$      \  __   $$ |$$ |           //
//     $$$$$$  |/  |  $$ |$$ |           //
//    /  \__$$ |$$ \__$$ |$$ |_____      //
//    $$    $$/ $$    $$/ $$       |     //
//     $$$$$$/   $$$$$$/  $$$$$$$$/      //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract MalcolmTowers is ERC1155Creator {
    constructor() ERC1155Creator("Editions By Malcolm Towers", "MalcolmTowers") {}
}