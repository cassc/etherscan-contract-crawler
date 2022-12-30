// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AmeT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//                           _______     //
//         /\               |__   __|    //
//        /  \   _ __ ___   ___| |       //
//       / /\ \ | '_ ` _ \ / _ \ |       //
//      / ____ \| | | | | |  __/ |       //
//     /_/    \_\_| |_| |_|\___|_|       //
//                                       //
//                                       //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract AmeT is ERC721Creator {
    constructor() ERC721Creator("AmeT", "AmeT") {}
}