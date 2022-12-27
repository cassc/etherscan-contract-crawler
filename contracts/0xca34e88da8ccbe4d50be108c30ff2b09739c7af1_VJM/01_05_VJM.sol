// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vita Jure Music
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//     _    _ _____ _______ _______      _____ _     _  ______ _______    //
//      \  /    |      |    |_____|        |   |     | |_____/ |______    //
//       \/   __|__    |    |     |      __|   |_____| |    \_ |______    //
//                                                                        //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract VJM is ERC1155Creator {
    constructor() ERC1155Creator("Vita Jure Music", "VJM") {}
}