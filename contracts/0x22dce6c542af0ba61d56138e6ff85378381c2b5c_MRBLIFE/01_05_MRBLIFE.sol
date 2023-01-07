// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Capturing Life by MisterBenjamin
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                                                         //
//      __  __ _____  ____  _      _____ ______ ______     //
//     |  \/  |  __ \|  _ \| |    |_   _|  ____|  ____|    //
//     | \  / | |__) | |_) | |      | | | |__  | |__       //
//     | |\/| |  _  /|  _ <| |      | | |  __| |  __|      //
//     | |  | | | \ \| |_) | |____ _| |_| |    | |____     //
//     |_|  |_|_|  \_\____/|______|_____|_|    |______|    //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract MRBLIFE is ERC1155Creator {
    constructor() ERC1155Creator("Capturing Life by MisterBenjamin", "MRBLIFE") {}
}