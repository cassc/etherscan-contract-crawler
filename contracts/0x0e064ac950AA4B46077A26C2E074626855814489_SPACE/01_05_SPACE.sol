// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Do Astronauts Dream of Alien Worlds?
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    ########  ########  ########    ###    ##     ##  ######      //
//    ##     ## ##     ## ##         ## ##   ###   ### ##    ##     //
//    ##     ## ##     ## ##        ##   ##  #### #### ##           //
//    ##     ## ########  ######   ##     ## ## ### ##  ######      //
//    ##     ## ##   ##   ##       ######### ##     ##       ##     //
//    ##     ## ##    ##  ##       ##     ## ##     ## ##    ##     //
//    ########  ##     ## ######## ##     ## ##     ##  ######      //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract SPACE is ERC1155Creator {
    constructor() ERC1155Creator("Do Astronauts Dream of Alien Worlds?", "SPACE") {}
}