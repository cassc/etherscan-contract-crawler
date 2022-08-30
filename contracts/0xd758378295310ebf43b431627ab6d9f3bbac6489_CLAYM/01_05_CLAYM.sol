// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ClayMasks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//       ___ _                              _            //
//      / __\ | __ _ _   _  /\/\   __ _ ___| | _____     //
//     / /  | |/ _` | | | |/    \ / _` / __| |/ / __|    //
//    / /___| | (_| | |_| / /\/\ \ (_| \__ \   <\__ \    //
//    \____/|_|\__,_|\__, \/    \/\__,_|___/_|\_\___/    //
//                   |___/ DevaMotion                    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract CLAYM is ERC721Creator {
    constructor() ERC721Creator("ClayMasks", "CLAYM") {}
}