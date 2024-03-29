// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blokssom DAO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//    ██████╗ ██╗      ██████╗ ██╗  ██╗███████╗███████╗ ██████╗ ███╗   ███╗    ██████╗  █████╗  ██████╗     //
//    ██╔══██╗██║     ██╔═══██╗██║ ██╔╝██╔════╝██╔════╝██╔═══██╗████╗ ████║    ██╔══██╗██╔══██╗██╔═══██╗    //
//    ██████╔╝██║     ██║   ██║█████╔╝ ███████╗███████╗██║   ██║██╔████╔██║    ██║  ██║███████║██║   ██║    //
//    ██╔══██╗██║     ██║   ██║██╔═██╗ ╚════██║╚════██║██║   ██║██║╚██╔╝██║    ██║  ██║██╔══██║██║   ██║    //
//    ██████╔╝███████╗╚██████╔╝██║  ██╗███████║███████║╚██████╔╝██║ ╚═╝ ██║    ██████╔╝██║  ██║╚██████╔╝    //
//    ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝     //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BDM is ERC721Creator {
    constructor() ERC721Creator("Blokssom DAO", "BDM") {}
}