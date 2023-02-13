// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fuma_test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//           _.---._    /\\        //
//        ./'       "--`\//        //
//      ./              o \        //
//     /./\  )______   \__ \       //
//    ./  / /\ \   | \ \  \ \      //
//       / /  \ \  | |\ \  \7      //
//        "     "    "  "          //
//                                 //
//                                 //
/////////////////////////////////////


contract fuma is ERC1155Creator {
    constructor() ERC1155Creator("fuma_test", "fuma") {}
}