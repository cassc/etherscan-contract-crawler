// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The World Through Mine
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//          ___.    _____                   //
//    _____ \_ |___/ ____\______  ____      //
//    \__  \ | __ \   __\\_  __ \/  _ \     //
//     / __ \| \_\ \  |   |  | \(  <_> )    //
//    (____  /___  /__|   |__|   \____/     //
//         \/    \/                         //
//                                          //
//                                          //
//////////////////////////////////////////////


contract EYE is ERC1155Creator {
    constructor() ERC1155Creator("The World Through Mine", "EYE") {}
}