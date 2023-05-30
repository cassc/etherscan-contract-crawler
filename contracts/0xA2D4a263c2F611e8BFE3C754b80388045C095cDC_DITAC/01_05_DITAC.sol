// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dita Crypto
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    ██████╗ ██╗████████╗ █████╗  ██████╗    //
//    ██╔══██╗██║╚══██╔══╝██╔══██╗██╔════╝    //
//    ██║  ██║██║   ██║   ███████║██║         //
//    ██║  ██║██║   ██║   ██╔══██║██║         //
//    ██████╔╝██║   ██║   ██║  ██║╚██████╗    //
//    ╚═════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝    //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract DITAC is ERC1155Creator {
    constructor() ERC1155Creator("Dita Crypto", "DITAC") {}
}