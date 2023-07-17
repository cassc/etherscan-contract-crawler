// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mfers & Frens
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     _            ___  _________  _____     //
//    | |           |  \/  || ___ \/  __ \    //
//    | |__  _   _  | .  . || |_/ /| /  \/    //
//    | '_ \| | | | | |\/| || ___ \| |        //
//    | |_) | |_| | | |  | || |_/ /| \__/\    //
//    |_.__/ \__, | \_|  |_/\____/  \____/    //
//            __/ |                           //
//           |___/                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MFERSF is ERC1155Creator {
    constructor() ERC1155Creator("Mfers & Frens", "MFERSF") {}
}