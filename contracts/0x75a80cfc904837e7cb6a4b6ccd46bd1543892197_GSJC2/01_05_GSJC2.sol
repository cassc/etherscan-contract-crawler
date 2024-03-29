// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Girl in the Silver Jacket for Collection No. 2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                                                                           //
//              _____                    _____                    _____      //
//             /\    \                  /\    \                  /\    \     //
//            /::\____\                /::\    \                /::\____\    //
//           /::::|   |               /::::\    \              /:::/    /    //
//          /:::::|   |              /::::::\    \            /:::/    /     //
//         /::::::|   |             /:::/\:::\    \          /:::/    /      //
//        /:::/|::|   |            /:::/  \:::\    \        /:::/    /       //
//       /:::/ |::|   |           /:::/    \:::\    \      /:::/    /        //
//      /:::/  |::|   | _____    /:::/    / \:::\    \    /:::/    /         //
//     /:::/   |::|   |/\    \  /:::/    /   \:::\ ___\  /:::/    /          //
//    /:: /    |::|   /::\____\/:::/____/  ___\:::|    |/:::/____/           //
//    \::/    /|::|  /:::/    /\:::\    \ /\  /:::|____|\:::\    \           //
//     \/____/ |::| /:::/    /  \:::\    /::\ \::/    /  \:::\    \          //
//             |::|/:::/    /    \:::\   \:::\ \/____/    \:::\    \         //
//             |::::::/    /      \:::\   \:::\____\       \:::\    \        //
//             |:::::/    /        \:::\  /:::/    /        \:::\    \       //
//             |::::/    /          \:::\/:::/    /          \:::\    \      //
//             /:::/    /            \::::::/    /            \:::\    \     //
//            /:::/    /              \::::/    /              \:::\____\    //
//            \::/    /                \::/____/                \::/    /    //
//             \/____/                                           \/____/     //
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract GSJC2 is ERC1155Creator {
    constructor() ERC1155Creator("Girl in the Silver Jacket for Collection No. 2", "GSJC2") {}
}