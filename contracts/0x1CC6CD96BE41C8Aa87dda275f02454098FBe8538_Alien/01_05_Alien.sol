// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 8liens 8rtist Collective
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//      ****   ****             //
//     */// * */// *            //
//    /*   /*/*   /*  *****     //
//    / **** / ****  **///**    //
//     */// * */// */**  //     //
//    /*   /*/*   /*/**   **    //
//    / **** / **** //*****     //
//     ////   ////   /////      //
//                              //
//                              //
//                              //
//                              //
//                              //
//                              //
//                              //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract Alien is ERC1155Creator {
    constructor() ERC1155Creator("8liens 8rtist Collective", "Alien") {}
}