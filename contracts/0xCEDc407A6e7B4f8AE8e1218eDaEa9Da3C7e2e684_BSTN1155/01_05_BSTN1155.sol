// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bastien Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//    ░██████╗░███╗░░░███╗    //
//    ██╔════╝░████╗░████║    //
//    ██║░░██╗░██╔████╔██║    //
//    ██║░░╚██╗██║╚██╔╝██║    //
//    ╚██████╔╝██║░╚═╝░██║    //
//    ░╚═════╝░╚═╝░░░░░╚═╝    //
//                            //
//                            //
////////////////////////////////


contract BSTN1155 is ERC1155Creator {
    constructor() ERC1155Creator("Bastien Editions", "BSTN1155") {}
}