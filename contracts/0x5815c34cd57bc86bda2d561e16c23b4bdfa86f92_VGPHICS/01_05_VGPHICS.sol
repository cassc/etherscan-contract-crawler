// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: vgraphics
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//     __   _____ ___    _   ___ _  _ ___ ___ ___     //
//     \ \ / / __| _ \  /_\ | _ \ || |_ _/ __/ __|    //
//      \ V / (_ |   / / _ \|  _/ __ || | (__\__ \    //
//       \_/ \___|_|_\/_/ \_\_| |_||_|___\___|___/    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract VGPHICS is ERC721Creator {
    constructor() ERC721Creator("vgraphics", "VGPHICS") {}
}