// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I am in a Cosmic Karma
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    ██╗░░██╗░█████╗░██████╗░███╗░░░███╗░█████╗░    //
//    ██║░██╔╝██╔══██╗██╔══██╗████╗░████║██╔══██╗    //
//    █████═╝░███████║██████╔╝██╔████╔██║███████║    //
//    ██╔═██╗░██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║    //
//    ██║░╚██╗██║░░██║██║░░██║██║░╚═╝░██║██║░░██║    //
//    ╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═╝░░╚═╝    //
//                                                   //
//    created by // nilcordan.eth                    //
//                                                   //
//    https://twitter.com/nilcordan                  //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract CRDN is ERC1155Creator {
    constructor() ERC1155Creator("I am in a Cosmic Karma", "CRDN") {}
}