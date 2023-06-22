// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: REYAI Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//     _ __  ________   _  _,   ___     //
//    ( /  )(  /  ( /  /  / |  ( /      //
//     /--<   /--  (__/  /--|   /       //
//    /   \_(/____/ _/__/   |__/_       //
//                 //                   //
//                (/                    //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract REY is ERC1155Creator {
    constructor() ERC1155Creator("REYAI Editions", "REY") {}
}