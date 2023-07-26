// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: That's Rad
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//    __________    _____  ________       //
//    \______   \  /  _  \ \______ \      //
//     |       _/ /  /_\  \ |    |  \     //
//     |    |   \/    |    \|    `   \    //
//     |____|_  /\____|__  /_______  /    //
//            \/         \/        \/     //
//                                        //
//                                        //
////////////////////////////////////////////


contract RAAD is ERC1155Creator {
    constructor() ERC1155Creator("That's Rad", "RAAD") {}
}