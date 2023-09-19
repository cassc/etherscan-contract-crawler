// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Days No Addiction
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//     ________   _____  ___        __          //
//    |"      "\ (\"   \|"  \      /""\         //
//    (.  ___  :)|.\\   \    |    /    \        //
//    |: \   ) |||: \.   \\  |   /' /\  \       //
//    (| (___\ |||.  \    \. |  //  __'  \      //
//    |:       :)|    \    \ | /   /  \\  \     //
//    (________/  \___|\____\)(___/    \___)    //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract DNA is ERC1155Creator {
    constructor() ERC1155Creator("Days No Addiction", "DNA") {}
}