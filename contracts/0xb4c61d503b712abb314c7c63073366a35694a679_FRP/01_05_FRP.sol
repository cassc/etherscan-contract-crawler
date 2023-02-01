// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FakeRektPepe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                                                                //
//                              ______ /  __  \   ____ _/  |_     //
//                             /  ___/ >      <  /    \\   __\    //
//                             \___ \ /   --   \|   |  \|  |      //
//                            /____  >\______  /|___|  /|__|      //
//                                 \/        \/      \/           //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract FRP is ERC1155Creator {
    constructor() ERC1155Creator("FakeRektPepe", "FRP") {}
}