// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JYD Monthly Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//     ▐▄▄▄ ▄· ▄▌·▄▄▄▄      //
//      ·██▐█▪██▌██▪ ██     //
//    ▪▄ ██▐█▌▐█▪▐█· ▐█▌    //
//    ▐▌▐█▌ ▐█▀·.██. ██     //
//     ▀▀▀•  ▀ • ▀▀▀▀▀•     //
//                          //
//                          //
//////////////////////////////


contract JYDMonthlyEditions is ERC1155Creator {
    constructor() ERC1155Creator("JYD Monthly Editions", "JYDMonthlyEditions") {}
}