// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ingenious Dreams
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//              _        _             //
//             /\ \     /\ \           //
//             \ \ \   /  \ \____      //
//             /\ \_\ / /\ \_____\     //
//            / /\/_// / /\/___  /     //
//           / / /  / / /   / / /      //
//          / / /  / / /   / / /       //
//         / / /  / / /   / / /        //
//     ___/ / /__ \ \ \__/ / /         //
//    /\__\/_/___\ \ \___\/ /          //
//    \/_________/  \/_____/           //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract ID is ERC721Creator {
    constructor() ERC721Creator("Ingenious Dreams", "ID") {}
}