// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moreso Project
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//                        //
//        _________       //
//     _ /_|_____|_\ _    //
//       '. \   / .'      //
//         '.\ /.'        //
//           '.'          //
//                        //
//                        //
////////////////////////////


contract MORESO is ERC721Creator {
    constructor() ERC721Creator("Moreso Project", "MORESO") {}
}