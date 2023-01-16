// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Why the Long Face?
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//     ___   __    ________   _________      //
//    /__/\ /__/\ /_______/\ /________/\     //
//    \::\_\\  \ \\::: _  \ \\__.::.__\/     //
//     \:. `-\  \ \\::(_)  \ \  \::\ \       //
//      \:. _    \ \\:: __  \ \  \::\ \      //
//       \. \`-\  \ \\:.\ \  \ \  \::\ \     //
//        \__\/ \__\/ \__\/\__\/   \__\/     //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract WTLF is ERC1155Creator {
    constructor() ERC1155Creator("Why the Long Face?", "WTLF") {}
}