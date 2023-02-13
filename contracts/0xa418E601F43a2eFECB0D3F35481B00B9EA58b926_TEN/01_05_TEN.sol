// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 2023-Valentine-test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Happy Valentine 2023    //
//     　__＿　＿__               //
//     ／　  V 　　＼              //
//    |　　　　　　　|               //
//     ＼　 2023　 ／             //
//    　 ＼　　　／                 //
//    　　　＼／                   //
//                            //
//                            //
////////////////////////////////


contract TEN is ERC1155Creator {
    constructor() ERC1155Creator("2023-Valentine-test", "TEN") {}
}