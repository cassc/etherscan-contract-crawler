// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM 6529
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//     $$$$$$\  $$\      $$\                      //
//    $$  __$$\ $$$\    $$$ |                     //
//    $$ /  \__|$$$$\  $$$$ |                     //
//    $$ |$$$$\ $$\$$\$$ $$ |                     //
//    $$ |\_$$ |$$ \$$$  $$ |                     //
//    $$ |  $$ |$$ |\$  /$$ |                     //
//    \$$$$$$  |$$ | \_/ $$ |                     //
//     \______/ \__|     \__|                     //
//                                                //
//                                                //
//                                                //
//     $$$$$$\  $$$$$$$\   $$$$$$\   $$$$$$\      //
//    $$  __$$\ $$  ____| $$  __$$\ $$  __$$\     //
//    $$ /  \__|$$ |      \__/  $$ |$$ /  $$ |    //
//    $$$$$$$\  $$$$$$$\   $$$$$$  |\$$$$$$$ |    //
//    $$  __$$\ \_____$$\ $$  ____/  \____$$ |    //
//    $$ /  $$ |$$\   $$ |$$ |      $$\   $$ |    //
//     $$$$$$  |\$$$$$$  |$$$$$$$$\ \$$$$$$  |    //
//     \______/  \______/ \________| \______/     //
//                                                //
//                                                //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract GM is ERC1155Creator {
    constructor() ERC1155Creator("GM 6529", "GM") {}
}