// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: By Oggo
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    \_____  \  /  _____/ /  _____/ \_____  \      //
//     /   |   \/   \  ___/   \  ___  /   |   \     //
//    /    |    \    \_\  \    \_\  \/    |    \    //
//    \_______  /\______  /\______  /\_______  /    //
//            \/        \/        \/         \/     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract LUCID is ERC1155Creator {
    constructor() ERC1155Creator("By Oggo", "LUCID") {}
}