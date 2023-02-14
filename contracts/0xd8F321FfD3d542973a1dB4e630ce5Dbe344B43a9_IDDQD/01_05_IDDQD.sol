// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IDDQD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//     _____ _____  _____   ____  _____        //
//    |_   _|  __ \|  __ \ / __ \|  __ \       //
//      | | | |  | | |  | | |  | | |  | |      //
//      | | | |  | | |  | | |  | | |  | |      //
//     _| |_| |__| | |__| | |__| | |__| |      //
//    |_____|_____/|_____/ \___\_\_____/ <3    //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract IDDQD is ERC721Creator {
    constructor() ERC721Creator("IDDQD", "IDDQD") {}
}