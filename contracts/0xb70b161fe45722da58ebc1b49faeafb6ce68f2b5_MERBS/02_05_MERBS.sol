// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Evolution by ROBENS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//     ____   ___  ____  _____ _   _ ____      //
//    |  _ \ / _ \| __ )| ____| \ | / ___|     //
//    | |_) | | | |  _ \|  _| |  \| \___ \     //
//    |  _ <| |_| | |_) | |___| |\  |___) |    //
//    |_| \_\\___/|____/|_____|_| \_|____/     //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract MERBS is ERC721Creator {
    constructor() ERC721Creator("My Evolution by ROBENS", "MERBS") {}
}