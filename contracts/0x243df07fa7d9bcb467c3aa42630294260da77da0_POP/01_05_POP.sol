// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Process Over Product
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//             _          _            _          //
//            /\ \       /\ \         /\ \        //
//           /  \ \     /  \ \       /  \ \       //
//          / /\ \ \   / /\ \ \     / /\ \ \      //
//         / / /\ \_\ / / /\ \ \   / / /\ \_\     //
//        / / /_/ / // / /  \ \_\ / / /_/ / /     //
//       / / /__\/ // / /   / / // / /__\/ /      //
//      / / /_____// / /   / / // / /_____/       //
//     / / /      / / /___/ / // / /              //
//    / / /      / / /____\/ // / /               //
//    \/_/       \/_________/ \/_/                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract POP is ERC721Creator {
    constructor() ERC721Creator("Process Over Product", "POP") {}
}