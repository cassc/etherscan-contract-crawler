// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cotama ToykenS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//     _______          _  ________ _   _         //
//    |__   __|        | |/ /  ____| \ | |        //
//       | | ___  _   _| ' /| |__  |  \| |___     //
//       | |/ _ \| | | |  < |  __| | . ` / __|    //
//       | | (_) | |_| | . \| |____| |\  \__ \    //
//       |_|\___/ \__, |_|\_\______|_| \_|___/    //
//                 __/ |                          //
//                |___/                           //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract ToyKenS is ERC721Creator {
    constructor() ERC721Creator("Cotama ToykenS", "ToyKenS") {}
}