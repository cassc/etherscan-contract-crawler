// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: This Is Water
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//     ____  _  _  __  ____            //
//    (_  _)/ )( \(  )/ ___)           //
//      )(  ) __ ( )( \___ \           //
//     (__) \_)(_/(__)(____/           //
//      __  ____                       //
//     (  )/ ___)                      //
//      )( \___ \                      //
//     (__)(____/                      //
//     _  _   __  ____  ____  ____     //
//    / )( \ / _\(_  _)(  __)(  _ \    //
//    \ /\ //    \ )(   ) _)  )   /    //
//    (_/\_)\_/\_/(__) (____)(__\_)    //
//                                     //
//                                     //
/////////////////////////////////////////


contract WATER is ERC721Creator {
    constructor() ERC721Creator("This Is Water", "WATER") {}
}