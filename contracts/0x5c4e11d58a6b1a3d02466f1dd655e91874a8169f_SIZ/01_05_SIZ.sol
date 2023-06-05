// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Splash Issue Zero
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//         /\         //
//     ,-.(  ),-.     //
//    ',-.\)(/,-.'    //
//      `-'\/`-'      //
//                    //
//                    //
////////////////////////


contract SIZ is ERC1155Creator {
    constructor() ERC1155Creator("Splash Issue Zero", "SIZ") {}
}