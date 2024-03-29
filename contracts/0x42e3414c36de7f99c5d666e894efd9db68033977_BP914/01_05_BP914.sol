// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: By Pietrus914
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//    ██████╗ ███████╗███████╗███████╗ █████╗ ██████╗  ██████╗██╗  ██╗       //
//    ██╔══██╗██╔════╝██╔════╝██╔════╝██╔══██╗██╔══██╗██╔════╝██║  ██║       //
//    ██████╔╝█████╗  ███████╗█████╗  ███████║██████╔╝██║     ███████║       //
//    ██╔══██╗██╔══╝  ╚════██║██╔══╝  ██╔══██║██╔══██╗██║     ██╔══██║       //
//    ██║  ██║███████╗███████║███████╗██║  ██║██║  ██║╚██████╗██║  ██║██╗    //
//    ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝    //
//    ██████╗  █████╗ ████████╗██╗███████╗███╗   ██╗ ██████╗███████╗         //
//    ██╔══██╗██╔══██╗╚══██╔══╝██║██╔════╝████╗  ██║██╔════╝██╔════╝         //
//    ██████╔╝███████║   ██║   ██║█████╗  ██╔██╗ ██║██║     █████╗           //
//    ██╔═══╝ ██╔══██║   ██║   ██║██╔══╝  ██║╚██╗██║██║     ██╔══╝           //
//    ██║     ██║  ██║   ██║   ██║███████╗██║ ╚████║╚██████╗███████╗██╗      //
//    ╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝      //
//                                                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract BP914 is ERC721Creator {
    constructor() ERC721Creator("By Pietrus914", "BP914") {}
}