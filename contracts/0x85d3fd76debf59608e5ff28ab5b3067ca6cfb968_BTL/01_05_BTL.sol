// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Betlis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

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


contract BTL is ERC721Creator {
    constructor() ERC721Creator("Betlis", "BTL") {}
}