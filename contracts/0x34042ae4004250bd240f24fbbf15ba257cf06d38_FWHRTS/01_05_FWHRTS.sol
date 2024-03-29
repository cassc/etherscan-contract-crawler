// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FewHearts Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//     ____                        __  __                          __                 //
//    /\  _`\                     /\ \/\ \                        /\ \__              //
//    \ \ \L\_\ __   __  __  __   \ \ \_\ \     __     __     _ __\ \ ,_\   ____      //
//     \ \  _\/'__`\/\ \/\ \/\ \   \ \  _  \  /'__`\ /'__`\  /\`'__\ \ \/  /',__\     //
//      \ \ \/\  __/\ \ \_/ \_/ \   \ \ \ \ \/\  __//\ \L\.\_\ \ \/ \ \ \_/\__, `\    //
//       \ \_\ \____\\ \___x___/'    \ \_\ \_\ \____\ \__/.\_\\ \_\  \ \__\/\____/    //
//        \/_/\/____/ \/__//__/       \/_/\/_/\/____/\/__/\/_/ \/_/   \/__/\/___/     //
//                                                                                    //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract FWHRTS is ERC1155Creator {
    constructor() ERC1155Creator("FewHearts Editions", "FWHRTS") {}
}