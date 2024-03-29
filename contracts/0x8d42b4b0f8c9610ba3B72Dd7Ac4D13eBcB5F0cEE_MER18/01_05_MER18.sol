// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 18CC MERCH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//       _        __      ____       ____               //
//     /' \     /'_ `\   /\  _`\    /\  _`\             //
//    /\_, \   /\ \L\ \  \ \ \/\_\  \ \ \/\_\           //
//    \/_/\ \  \/_> _ <_  \ \ \/_/_  \ \ \/_/_          //
//       \ \ \   /\ \L\ \  \ \ \L\ \  \ \ \L\ \         //
//        \ \_\  \ \____/   \ \____/   \ \____/         //
//         \/_/   \/___/     \/___/     \/___/          //
//                                                      //
//                                                      //
//                 ____       __         ____           //
//     /'\_/`\    /\  _`\    /\ \       /\  _`\         //
//    /\      \   \ \ \L\_\  \ \ \      \ \ \L\ \       //
//    \ \ \__\ \   \ \  _\L   \ \ \  __  \ \  _ <'      //
//     \ \ \_/\ \   \ \ \L\ \  \ \ \L\ \  \ \ \L\ \     //
//      \ \_\\ \_\   \ \____/   \ \____/   \ \____/     //
//       \/_/ \/_/    \/___/     \/___/     \/___/      //
//                                                      //
//                                                      //
//     ______      __  __      ____        ______       //
//    /\  _  \    /\ \/\ \    /\  _`\     /\__  _\      //
//    \ \ \L\ \   \ \ \ \ \   \ \,\L\_\   \/_/\ \/      //
//     \ \  __ \   \ \ \ \ \   \/_\__ \      \ \ \      //
//      \ \ \/\ \   \ \ \_\ \    /\ \L\ \     \ \ \     //
//       \ \_\ \_\   \ \_____\   \ `\____\     \ \_\    //
//        \/_/\/_/    \/_____/    \/_____/      \/_/    //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract MER18 is ERC721Creator {
    constructor() ERC721Creator("18CC MERCH", "MER18") {}
}