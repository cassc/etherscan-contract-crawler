// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Void Surviving
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//                             //
//     __      __ _  _____     //
//     \ \    / /| |/ ____|    //
//      \ \  / /_| | (___      //
//       \ \/ / _` |\___ \     //
//        \  / (_| |____) |    //
//         \/ \__,_|_____/     //
//                             //
//                             //
//                             //
//                             //
//                             //
/////////////////////////////////


contract Vds is ERC721Creator {
    constructor() ERC721Creator("Void Surviving", "Vds") {}
}