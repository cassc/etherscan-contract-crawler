// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IAMTHEMISTERX
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//    ███╗░░░███╗██████╗░██╗░░██╗    //
//    ████╗░████║██╔══██╗╚██╗██╔╝    //
//    ██╔████╔██║██████╔╝░╚███╔╝░    //
//    ██║╚██╔╝██║██╔══██╗░██╔██╗░    //
//    ██║░╚═╝░██║██║░░██║██╔╝╚██╗    //
//    ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝    //
//                                   //
//                                   //
///////////////////////////////////////


contract MRX is ERC1155Creator {
    constructor() ERC1155Creator("IAMTHEMISTERX", "MRX") {}
}