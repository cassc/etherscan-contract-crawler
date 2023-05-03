// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Real Vibe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//               $$\ $$\                     //
//               \__|$$ |                    //
//    $$\    $$\ $$\ $$$$$$$\   $$$$$$\      //
//    \$$\  $$  |$$ |$$  __$$\ $$  __$$\     //
//     \$$\$$  / $$ |$$ |  $$ |$$$$$$$$ |    //
//      \$$$  /  $$ |$$ |  $$ |$$   ____|    //
//       \$  /   $$ |$$$$$$$  |\$$$$$$$\     //
//        \_/    \__|\_______/  \_______|    //
//                                           //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract TRV is ERC721Creator {
    constructor() ERC721Creator("The Real Vibe", "TRV") {}
}