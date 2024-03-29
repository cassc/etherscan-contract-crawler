// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Golden Hour - Special Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//              _____                    _____                    _____                _____                    _____                    _____                    _____                    _____                _____              //
//             /\    \                  /\    \                  /\    \              |\    \                  /\    \                  /\    \                  /\    \                  /\    \              /\    \             //
//            /::\    \                /::\____\                /::\    \             |:\____\                /::\____\                /::\    \                /::\    \                /::\    \            /::\    \            //
//           /::::\    \              /::::|   |               /::::\    \            |::|   |               /::::|   |               /::::\    \              /::::\    \              /::::\    \           \:::\    \           //
//          /::::::\    \            /:::::|   |              /::::::\    \           |::|   |              /:::::|   |              /::::::\    \            /::::::\    \            /::::::\    \           \:::\    \          //
//         /:::/\:::\    \          /::::::|   |             /:::/\:::\    \          |::|   |             /::::::|   |             /:::/\:::\    \          /:::/\:::\    \          /:::/\:::\    \           \:::\    \         //
//        /:::/__\:::\    \        /:::/|::|   |            /:::/  \:::\    \         |::|   |            /:::/|::|   |            /:::/  \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \           \:::\    \        //
//       /::::\   \:::\    \      /:::/ |::|   |           /:::/    \:::\    \        |::|   |           /:::/ |::|   |           /:::/    \:::\    \      /::::\   \:::\    \      /::::\   \:::\    \          /::::\    \       //
//      /::::::\   \:::\    \    /:::/  |::|   | _____    /:::/    / \:::\    \       |::|___|______    /:::/  |::|   | _____    /:::/    / \:::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \        /::::::\    \      //
//     /:::/\:::\   \:::\    \  /:::/   |::|   |/\    \  /:::/    /   \:::\ ___\      /::::::::\    \  /:::/   |::|   |/\    \  /:::/    /   \:::\ ___\  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\      /:::/\:::\    \     //
//    /:::/  \:::\   \:::\____\/:: /    |::|   /::\____\/:::/____/     \:::|    |    /::::::::::\____\/:: /    |::|   /::\____\/:::/____/     \:::|    |/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |    /:::/  \:::\____\    //
//    \::/    \:::\  /:::/    /\::/    /|::|  /:::/    /\:::\    \     /:::|____|   /:::/~~~~/~~      \::/    /|::|  /:::/    /\:::\    \     /:::|____|\::/    \:::\  /:::/    /\::/   |::::\  /:::|____|   /:::/    \::/    /    //
//     \/____/ \:::\/:::/    /  \/____/ |::| /:::/    /  \:::\    \   /:::/    /   /:::/    /          \/____/ |::| /:::/    /  \:::\    \   /:::/    /  \/____/ \:::\/:::/    /  \/____|:::::\/:::/    /   /:::/    / \/____/     //
//              \::::::/    /           |::|/:::/    /    \:::\    \ /:::/    /   /:::/    /                   |::|/:::/    /    \:::\    \ /:::/    /            \::::::/    /         |:::::::::/    /   /:::/    /              //
//               \::::/    /            |::::::/    /      \:::\    /:::/    /   /:::/    /                    |::::::/    /      \:::\    /:::/    /              \::::/    /          |::|\::::/    /   /:::/    /               //
//               /:::/    /             |:::::/    /        \:::\  /:::/    /    \::/    /                     |:::::/    /        \:::\  /:::/    /               /:::/    /           |::| \::/____/    \::/    /                //
//              /:::/    /              |::::/    /          \:::\/:::/    /      \/____/                      |::::/    /          \:::\/:::/    /               /:::/    /            |::|  ~|           \/____/                 //
//             /:::/    /               /:::/    /            \::::::/    /                                    /:::/    /            \::::::/    /               /:::/    /             |::|   |                                   //
//            /:::/    /               /:::/    /              \::::/    /                                    /:::/    /              \::::/    /               /:::/    /              \::|   |                                   //
//            \::/    /                \::/    /                \::/____/                                     \::/    /                \::/____/                \::/    /                \:|   |                                   //
//             \/____/                  \/____/                  ~~                                            \/____/                  ~~                       \/____/                  \|___|                                   //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GH is ERC1155Creator {
    constructor() ERC1155Creator() {}
}