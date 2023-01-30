// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: stuz0r
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//              __               _______             //
//      _______/  |_ __ _________\   _  \_______     //
//     /  ___/\   __\  |  \___   /  /_\  \_  __ \    //
//     \___ \  |  | |  |  //    /\  \_/   \  | \/    //
//    /____  > |__| |____//_____ \\_____  /__|       //
//         \/                   \/      \/           //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract stuz0r is ERC721Creator {
    constructor() ERC721Creator("stuz0r", "stuz0r") {}
}