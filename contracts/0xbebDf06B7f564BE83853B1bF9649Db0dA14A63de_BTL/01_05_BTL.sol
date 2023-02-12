// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Betlis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//    ,-----. ,--------.,--.        //
//    |  |) /_'--.  .--'|  |        //
//    |  .-.  \  |  |   |  |        //
//    |  '--' /  |  |   |  '--.     //
//    `------'   `--'   `-----'     //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract BTL is ERC1155Creator {
    constructor() ERC1155Creator("Betlis", "BTL") {}
}