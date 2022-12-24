// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oh Wells Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//      __   _        _              _   _             //
//      /\_\/| |      (_|   |   |_/  | | | |           //
//     |    || |        |   |   | _  | | | |  ,        //
//     |    ||/ \       |   |   ||/  |/  |/  / \_      //
//      \__/ |   |_/     \_/ \_/ |__/|__/|__/ \/       //
//     / (_)   |  o     o                              //
//     \__   __|    _|_     __   _  _    ,             //
//     /    /  |  |  |  |  /  \_/ |/ |  / \_           //
//     \___/\_/|_/|_/|_/|_/\__/   |  |_/ \/            //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract OhWells is ERC1155Creator {
    constructor() ERC1155Creator("Oh Wells Editions", "OhWells") {}
}