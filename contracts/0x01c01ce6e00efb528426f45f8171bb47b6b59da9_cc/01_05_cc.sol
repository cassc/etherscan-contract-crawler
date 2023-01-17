// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: catchees
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//            ______         __        //
//      ______/  __  \  _____/  |_     //
//     /  ___/>      < /    \   __\    //
//     \___ \/   --   \   |  \  |      //
//    /____  >______  /___|  /__|      //
//         \/       \/     \/          //
//                                     //
//                                     //
/////////////////////////////////////////


contract cc is ERC721Creator {
    constructor() ERC721Creator("catchees", "cc") {}
}