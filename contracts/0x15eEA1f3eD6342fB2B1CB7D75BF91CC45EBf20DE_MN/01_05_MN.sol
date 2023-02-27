// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mellifluous Noise
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    •             //
//    ••            //
//    •••           //
//    ••••          //
//    •••••         //
//    ••••••        //
//    •••••••       //
//    ••••••••      //
//    •••••••••     //
//    ••••••••••    //
//    •••••••••     //
//    ••••••••      //
//    •••••••       //
//    ••••••        //
//    •••••         //
//    ••••          //
//    •••           //
//    ••            //
//    •             //
//                  //
//                  //
//////////////////////


contract MN is ERC721Creator {
    constructor() ERC721Creator("Mellifluous Noise", "MN") {}
}