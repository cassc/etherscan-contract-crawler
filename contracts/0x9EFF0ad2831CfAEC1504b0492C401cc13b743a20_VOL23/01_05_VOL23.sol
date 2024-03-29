// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VOLUME 2023
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//              _____                    _____                    _____                    _____                    _____              //
//             /\    \                  /\    \                  /\    \                  /\    \                  /\    \             //
//            /::\    \                /::\    \                /::\____\                /::\____\                /::\    \            //
//           /::::\    \              /::::\    \              /::::|   |               /::::|   |               /::::\    \           //
//          /::::::\    \            /::::::\    \            /:::::|   |              /:::::|   |              /::::::\    \          //
//         /:::/\:::\    \          /:::/\:::\    \          /::::::|   |             /::::::|   |             /:::/\:::\    \         //
//        /:::/  \:::\    \        /:::/__\:::\    \        /:::/|::|   |            /:::/|::|   |            /:::/__\:::\    \        //
//       /:::/    \:::\    \      /::::\   \:::\    \      /:::/ |::|   |           /:::/ |::|   |           /::::\   \:::\    \       //
//      /:::/    / \:::\    \    /::::::\   \:::\    \    /:::/  |::|   | _____    /:::/  |::|   | _____    /::::::\   \:::\    \      //
//     /:::/    /   \:::\ ___\  /:::/\:::\   \:::\    \  /:::/   |::|   |/\    \  /:::/   |::|   |/\    \  /:::/\:::\   \:::\    \     //
//    /:::/____/     \:::|    |/:::/  \:::\   \:::\____\/:: /    |::|   /::\____\/:: /    |::|   /::\____\/:::/__\:::\   \:::\____\    //
//    \:::\    \     /:::|____|\::/    \:::\  /:::/    /\::/    /|::|  /:::/    /\::/    /|::|  /:::/    /\:::\   \:::\   \::/    /    //
//     \:::\    \   /:::/    /  \/____/ \:::\/:::/    /  \/____/ |::| /:::/    /  \/____/ |::| /:::/    /  \:::\   \:::\   \/____/     //
//      \:::\    \ /:::/    /            \::::::/    /           |::|/:::/    /           |::|/:::/    /    \:::\   \:::\    \         //
//       \:::\    /:::/    /              \::::/    /            |::::::/    /            |::::::/    /      \:::\   \:::\____\        //
//        \:::\  /:::/    /               /:::/    /             |:::::/    /             |:::::/    /        \:::\   \::/    /        //
//         \:::\/:::/    /               /:::/    /              |::::/    /              |::::/    /          \:::\   \/____/         //
//          \::::::/    /               /:::/    /               /:::/    /               /:::/    /            \:::\    \             //
//           \::::/    /               /:::/    /               /:::/    /               /:::/    /              \:::\____\            //
//            \::/____/                \::/    /                \::/    /                \::/    /                \::/    /            //
//             ~~                       \/____/                  \/____/                  \/____/                  \/____/             //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VOL23 is ERC721Creator {
    constructor() ERC721Creator("VOLUME 2023", "VOL23") {}
}