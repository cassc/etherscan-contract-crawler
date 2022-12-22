// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rienneit Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//    ██████╗ ██╗███████╗███╗   ██╗ ██████╗    //
//    ██╔══██╗██║██╔════╝████╗  ██║██╔════╝    //
//    ██████╔╝██║█████╗  ██╔██╗ ██║██║         //
//    ██╔══██╗██║██╔══╝  ██║╚██╗██║██║         //
//    ██║  ██║██║███████╗██║ ╚████║╚██████╗    //
//    ╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝    //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract RIENC is ERC1155Creator {
    constructor() ERC1155Creator("Rienneit Collection", "RIENC") {}
}