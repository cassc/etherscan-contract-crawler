// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CMM Test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//       _____ __  __   _______        _       //
//      / ____|  \/  | |__   __|      | |      //
//     | |    | \  / |    | | ___  ___| |_     //
//     | |    | |\/| |    | |/ _ \/ __| __|    //
//     | |____| |  | |    | |  __/\__ \ |_     //
//      \_____|_|  |_|    |_|\___||___/\__|    //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract CMT is ERC721Creator {
    constructor() ERC721Creator("CMM Test", "CMT") {}
}