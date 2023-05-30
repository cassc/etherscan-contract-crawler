// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CWC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
//       _______          _______     //
//      / ____\ \        / / ____|    //
//     | |     \ \  /\  / / |         //
//     | |      \ \/  \/ /| |         //
//     | |____   \  /\  / | |____     //
//      \_____|   \/  \/   \_____|    //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract CWC is ERC721Creator {
    constructor() ERC721Creator("CWC", "CWC") {}
}