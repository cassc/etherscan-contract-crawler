// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The King of Gorillas
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//        ____   _                           ____   __ __    //
//       / __ \ (_)___   _____ __  __ ____  / __ \ / // /    //
//      / /_/ // // _ \ / ___// / / //_  / / /_/ // // /_    //
//     / ____// //  __// /   / /_/ /  / /_ \__, //__  __/    //
//    /_/    /_/ \___//_/    \__,_/  /___//____/   /_/       //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract TKG is ERC721Creator {
    constructor() ERC721Creator("The King of Gorillas", "TKG") {}
}