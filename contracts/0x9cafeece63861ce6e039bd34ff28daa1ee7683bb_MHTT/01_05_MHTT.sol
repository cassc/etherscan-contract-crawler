// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MANHATTAN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//              _____                    _____                    _____                    _____                    _____                _____                _____                    _____                    _____              //
//             /\    \                  /\    \                  /\    \                  /\    \                  /\    \              /\    \              /\    \                  /\    \                  /\    \             //
//            /::\____\                /::\    \                /::\____\                /::\____\                /::\    \            /::\    \            /::\    \                /::\    \                /::\____\            //
//           /::::|   |               /::::\    \              /::::|   |               /:::/    /               /::::\    \           \:::\    \           \:::\    \              /::::\    \              /::::|   |            //
//          /:::::|   |              /::::::\    \            /:::::|   |              /:::/    /               /::::::\    \           \:::\    \           \:::\    \            /::::::\    \            /:::::|   |            //
//         /::::::|   |             /:::/\:::\    \          /::::::|   |             /:::/    /               /:::/\:::\    \           \:::\    \           \:::\    \          /:::/\:::\    \          /::::::|   |            //
//        /:::/|::|   |            /:::/__\:::\    \        /:::/|::|   |            /:::/____/               /:::/__\:::\    \           \:::\    \           \:::\    \        /:::/__\:::\    \        /:::/|::|   |            //
//       /:::/ |::|   |           /::::\   \:::\    \      /:::/ |::|   |           /::::\    \              /::::\   \:::\    \          /::::\    \          /::::\    \      /::::\   \:::\    \      /:::/ |::|   |            //
//      /:::/  |::|___|______    /::::::\   \:::\    \    /:::/  |::|   | _____    /::::::\    \   _____    /::::::\   \:::\    \        /::::::\    \        /::::::\    \    /::::::\   \:::\    \    /:::/  |::|   | _____      //
//     /:::/   |::::::::\    \  /:::/\:::\   \:::\    \  /:::/   |::|   |/\    \  /:::/\:::\    \ /\    \  /:::/\:::\   \:::\    \      /:::/\:::\    \      /:::/\:::\    \  /:::/\:::\   \:::\    \  /:::/   |::|   |/\    \     //
//    /:::/    |:::::::::\____\/:::/  \:::\   \:::\____\/:: /    |::|   /::\____\/:::/  \:::\    /::\____\/:::/  \:::\   \:::\____\    /:::/  \:::\____\    /:::/  \:::\____\/:::/  \:::\   \:::\____\/:: /    |::|   /::\____\    //
//    \::/    / ~~~~~/:::/    /\::/    \:::\  /:::/    /\::/    /|::|  /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::/    /   /:::/    \::/    /   /:::/    \::/    /\::/    \:::\  /:::/    /\::/    /|::|  /:::/    /    //
//     \/____/      /:::/    /  \/____/ \:::\/:::/    /  \/____/ |::| /:::/    /  \/____/ \:::\/:::/    /  \/____/ \:::\/:::/    /   /:::/    / \/____/   /:::/    / \/____/  \/____/ \:::\/:::/    /  \/____/ |::| /:::/    /     //
//                 /:::/    /            \::::::/    /           |::|/:::/    /            \::::::/    /            \::::::/    /   /:::/    /           /:::/    /                    \::::::/    /           |::|/:::/    /      //
//                /:::/    /              \::::/    /            |::::::/    /              \::::/    /              \::::/    /   /:::/    /           /:::/    /                      \::::/    /            |::::::/    /       //
//               /:::/    /               /:::/    /             |:::::/    /               /:::/    /               /:::/    /    \::/    /            \::/    /                       /:::/    /             |:::::/    /        //
//              /:::/    /               /:::/    /              |::::/    /               /:::/    /               /:::/    /      \/____/              \/____/                       /:::/    /              |::::/    /         //
//             /:::/    /               /:::/    /               /:::/    /               /:::/    /               /:::/    /                                                         /:::/    /               /:::/    /          //
//            /:::/    /               /:::/    /               /:::/    /               /:::/    /               /:::/    /                                                         /:::/    /               /:::/    /           //
//            \::/    /                \::/    /                \::/    /                \::/    /                \::/    /                                                          \::/    /                \::/    /            //
//             \/____/                  \/____/                  \/____/                  \/____/                  \/____/                                                            \/____/                  \/____/             //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MHTT is ERC721Creator {
    constructor() ERC721Creator("MANHATTAN", "MHTT") {}
}