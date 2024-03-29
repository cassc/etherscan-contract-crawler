// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mahō shōjo
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//              _____                   _____                   _____                  _______                           _____                   _____                  _______                  _____                  _______             //
//             /\    \                 /\    \                 /\    \                /::\    \                         /\    \                 /\    \                /::\    \                /\    \                /::\    \            //
//            /::\____\               /::\    \               /::\____\              /::::\    \                       /::\    \               /::\____\              /::::\    \              /::\    \              /::::\    \           //
//           /::::|   |              /::::\    \             /:::/    /             /::::::\    \                     /::::\    \             /:::/    /             /::::::\    \             \:::\    \            /::::::\    \          //
//          /:::::|   |             /::::::\    \           /:::/    /             /::::::::\    \                   /::::::\    \           /:::/    /             /::::::::\    \             \:::\    \          /::::::::\    \         //
//         /::::::|   |            /:::/\:::\    \         /:::/    /             /:::/~~\:::\    \                 /:::/\:::\    \         /:::/    /             /:::/~~\:::\    \             \:::\    \        /:::/~~\:::\    \        //
//        /:::/|::|   |           /:::/__\:::\    \       /:::/____/             /:::/    \:::\    \               /:::/__\:::\    \       /:::/____/             /:::/    \:::\    \             \:::\    \      /:::/    \:::\    \       //
//       /:::/ |::|   |          /::::\   \:::\    \     /::::\    \            /:::/    / \:::\    \              \:::\   \:::\    \     /::::\    \            /:::/    / \:::\    \            /::::\    \    /:::/    / \:::\    \      //
//      /:::/  |::|___|______   /::::::\   \:::\    \   /::::::\    \   _____  /:::/____/   \:::\____\           ___\:::\   \:::\    \   /::::::\    \   _____  /:::/____/   \:::\____\  _____   /::::::\    \  /:::/____/   \:::\____\     //
//     /:::/   |::::::::\    \ /:::/\:::\   \:::\    \ /:::/\:::\    \ /\    \|:::|    |     |:::|    |         /\   \:::\   \:::\    \ /:::/\:::\    \ /\    \|:::|    |     |:::|    |/\    \ /:::/\:::\    \|:::|    |     |:::|    |    //
//    /:::/    |:::::::::\____/:::/  \:::\   \:::\____/:::/  \:::\    /::\____|:::|____|     |:::|    |        /::\   \:::\   \:::\____/:::/  \:::\    /::\____|:::|____|     |:::|    /::\    /:::/  \:::\____|:::|____|     |:::|    |    //
//    \::/    / ~~~~~/:::/    \::/    \:::\  /:::/    \::/    \:::\  /:::/    /\:::\    \   /:::/    /         \:::\   \:::\   \::/    \::/    \:::\  /:::/    /\:::\    \   /:::/    /\:::\  /:::/    \::/    /\:::\    \   /:::/    /     //
//     \/____/      /:::/    / \/____/ \:::\/:::/    / \/____/ \:::\/:::/    /  \:::\    \ /:::/    /           \:::\   \:::\   \/____/ \/____/ \:::\/:::/    /  \:::\    \ /:::/    /  \:::\/:::/    / \/____/  \:::\    \ /:::/    /      //
//                 /:::/    /           \::::::/    /           \::::::/    /    \:::\    /:::/    /             \:::\   \:::\    \              \::::::/    /    \:::\    /:::/    /    \::::::/    /            \:::\    /:::/    /       //
//                /:::/    /             \::::/    /             \::::/    /      \:::\__/:::/    /               \:::\   \:::\____\              \::::/    /      \:::\__/:::/    /      \::::/    /              \:::\__/:::/    /        //
//               /:::/    /              /:::/    /              /:::/    /        \::::::::/    /                 \:::\  /:::/    /              /:::/    /        \::::::::/    /        \::/    /                \::::::::/    /         //
//              /:::/    /              /:::/    /              /:::/    /          \::::::/    /                   \:::\/:::/    /              /:::/    /          \::::::/    /          \/____/                  \::::::/    /          //
//             /:::/    /              /:::/    /              /:::/    /            \::::/    /                     \::::::/    /              /:::/    /            \::::/    /                                     \::::/    /           //
//            /:::/    /              /:::/    /              /:::/    /              \::/____/                       \::::/    /              /:::/    /              \::/____/                                       \::/____/            //
//            \::/    /               \::/    /               \::/    /                ~~                              \::/    /               \::/    /                ~~                                              ~~                  //
//             \/____/                 \/____/                 \/____/                                                  \/____/                 \/____/                                                                                     //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Shojo is ERC721Creator {
    constructor() ERC721Creator(unicode"Mahō shōjo", "Shojo") {}
}