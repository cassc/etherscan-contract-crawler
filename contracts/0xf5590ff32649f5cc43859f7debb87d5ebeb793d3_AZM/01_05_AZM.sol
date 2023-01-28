// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anna Zubarev x Mpozzecco
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//                                             //
//                         __  __   ___        //
//                        |  |/  `.'   `.      //
//                        |   .-.  .-.   '     //
//        __              |  |  |  |  |  |     //
//     .:--.'.  .--------.|  |  |  |  |  |     //
//    / |   \ | |____    ||  |  |  |  |  |     //
//    `" __ | |     /   / |  |  |  |  |  |     //
//     .'.''| |   .'   /  |__|  |__|  |__|     //
//    / /   | |_ /    /___                     //
//    \ \._,\ '/|         |                    //
//     `--'  `" |_________|                    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract AZM is ERC1155Creator {
    constructor() ERC1155Creator("Anna Zubarev x Mpozzecco", "AZM") {}
}