// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OL1Y BIDDER EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//     ________  ___     _____      ___    ___     //
//    |\   __  \|\  \   / __  \    |\  \  /  /|    //
//    \ \  \|\  \ \  \ |\/_|\  \   \ \  \/  / /    //
//     \ \  \\\  \ \  \\|/ \ \  \   \ \    / /     //
//      \ \  \\\  \ \  \____\ \  \   \/  /  /      //
//       \ \_______\ \_______\ \__\__/  / /        //
//        \|_______|\|_______|\|__|\___/ /         //
//                                \|___|/          //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract OL1YBD is ERC1155Creator {
    constructor() ERC1155Creator("OL1Y BIDDER EDITIONS", "OL1YBD") {}
}