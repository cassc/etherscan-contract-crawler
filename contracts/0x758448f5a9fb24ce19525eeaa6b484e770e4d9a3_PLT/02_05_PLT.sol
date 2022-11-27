// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pilot
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//             _______________       //
//            /               \      //
//           /                 \     //
//          /                   \    //
//          |   XXXX     XXXX   |    //
//          |   XXXX     XXXX   |    //
//          |   XXX       XXX   |    //
//          |         X         |    //
//          \__      XXX     __/     //
//            |\     XXX     /|      //
//            | |           | |      //
//            | I I I I I I I |      //
//            |  I I I I I I  |      //
//             \_           _/       //
//              \_         _/        //
//                \_______/          //
//                                   //
//                                   //
///////////////////////////////////////


contract PLT is ERC721Creator {
    constructor() ERC721Creator("Pilot", "PLT") {}
}