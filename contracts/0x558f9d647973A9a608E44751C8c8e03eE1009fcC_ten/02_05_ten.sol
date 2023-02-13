// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Valentine 2023
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//        Happy Valentine 2023        //
//         　__＿　＿__                   //
//         ／　  V 　　＼                  //
//        |　　　　　　　|                   //
//         ＼　 2023　 ／                 //
//        　 ＼　　　／                     //
//        　　　＼／                       //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract ten is ERC1155Creator {
    constructor() ERC1155Creator("Valentine 2023", "ten") {}
}