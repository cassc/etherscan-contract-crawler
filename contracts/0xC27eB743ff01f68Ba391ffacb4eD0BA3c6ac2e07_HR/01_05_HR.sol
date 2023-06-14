// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hidden Room
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//     __________     //
//    |  __  __  |    //
//    | |  ||  | |    //
//    | |  ||  | |    //
//    | |__||__| |    //
//    |  __  __()|    //
//    | |  ||  | |    //
//    | |  ||  | |    //
//    | |  ||  | |    //
//    | |  ||  | |    //
//    | |__||__| |    //
//    |__________|    //
//     ɯooɹ uǝppᴉɥ    //
//                    //
//                    //
////////////////////////


contract HR is ERC721Creator {
    constructor() ERC721Creator("Hidden Room", "HR") {}
}