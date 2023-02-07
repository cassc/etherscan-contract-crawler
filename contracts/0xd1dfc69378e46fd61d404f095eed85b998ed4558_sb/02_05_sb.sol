// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sadbow
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//         _.-""""`-._         //
//       ,' _-""""`-_ `.       //
//      / ,'.-'"""`-.`. \      //
//     | / / ,'"""`. \ \ |     //
//    | | | | ,'"`. | | | |    //
//    | | | | |   | | | | |    //
//                             //
//                             //
/////////////////////////////////


contract sb is ERC721Creator {
    constructor() ERC721Creator("sadbow", "sb") {}
}