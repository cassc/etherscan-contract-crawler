// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MIRARAHIIM
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//      __  __   _____   _____               _   _     //
//     |  \/  | |_   _| |  __ \      /\     | \ | |    //
//     | \  / |   | |   | |__) |    /  \    |  \| |    //
//     | |\/| |   | |   |  _  /    / /\ \   | . ` |    //
//     | |  | |  _| |_  | | \ \   / ____ \  | |\  |    //
//     |_|  |_| |_____| |_|  \_\ /_/    \_\ |_| \_|    //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract MIV is ERC1155Creator {
    constructor() ERC1155Creator("MIRARAHIIM", "MIV") {}
}