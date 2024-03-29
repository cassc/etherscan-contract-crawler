// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aesthetics of perception
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                               //
//                                                                                                                               //
//         _____/\/\______/\/\________________________________/\/\__________________________________________________/\/\_____    //
//        ___/\/\/\/\____/\/\______/\/\/\____/\/\__/\/\______/\/\________/\/\/\______/\/\/\__/\/\____/\/\/\______/\/\/\/\/\_     //
//       _/\/\____/\/\__/\/\____/\/\/\/\/\____/\/\/\________/\/\____________/\/\____/\/\/\/\/\/\/\______/\/\______/\/\_____      //
//      _/\/\/\/\/\/\__/\/\____/\/\__________/\/\/\________/\/\________/\/\/\/\____/\/\__/\__/\/\__/\/\/\/\______/\/\_____       //
//     _/\/\____/\/\__/\/\/\____/\/\/\/\__/\/\__/\/\______/\/\/\/\/\__/\/\/\/\/\__/\/\______/\/\__/\/\/\/\/\____/\/\/\___        //
//    __________________________________________________________________________________________________________________         //
//                                                                                                                               //
//    “Aesthetics of perception” by Alex Lamat                                                                                   //
//    12.2022                                                                                                                    //
//                                                                                                                               //
//                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALM is ERC721Creator {
    constructor() ERC721Creator("Aesthetics of perception", "ALM") {}
}