// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NSS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//    ███╗   ██╗███████╗███████╗    //
//    ████╗  ██║██╔════╝██╔════╝    //
//    ██╔██╗ ██║███████╗███████╗    //
//    ██║╚██╗██║╚════██║╚════██║    //
//    ██║ ╚████║███████║███████║    //
//    ╚═╝  ╚═══╝╚══════╝╚══════╝    //
//                                  //
//                                  //
//////////////////////////////////////


contract NSS is ERC1155Creator {
    constructor() ERC1155Creator("NSS", "NSS") {}
}