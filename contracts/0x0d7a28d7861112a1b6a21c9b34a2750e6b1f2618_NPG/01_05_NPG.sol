// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFTOUJI PASS GENESIS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//     __  __  ____    ____          //
//    /\ \/\ \/\  _`\ /\  _`\        //
//    \ \ `\\ \ \ \L\ \ \ \L\_\      //
//     \ \ , ` \ \ ,__/\ \ \L_L      //
//      \ \ \`\ \ \ \/  \ \ \/, \    //
//       \ \_\ \_\ \_\   \ \____/    //
//        \/_/\/_/\/_/    \/___/     //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract NPG is ERC1155Creator {
    constructor() ERC1155Creator("NFTOUJI PASS GENESIS", "NPG") {}
}