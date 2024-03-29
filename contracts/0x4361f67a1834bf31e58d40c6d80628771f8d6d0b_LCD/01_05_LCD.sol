// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lucid-dreamer
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                                                                   //
//    ██╗░░░░░██╗░░░██╗░█████╗░██╗██████╗░                           //
//    ██║░░░░░██║░░░██║██╔══██╗██║██╔══██╗                           //
//    ██║░░░░░██║░░░██║██║░░╚═╝██║██║░░██║                           //
//    ██║░░░░░██║░░░██║██║░░██╗██║██║░░██║                           //
//    ███████╗╚██████╔╝╚█████╔╝██║██████╔╝                           //
//    ╚══════╝░╚═════╝░░╚════╝░╚═╝╚═════╝░                           //
//                                                                   //
//    ██████╗░██████╗░███████╗░█████╗░███╗░░░███╗███████╗██████╗░    //
//    ██╔══██╗██╔══██╗██╔════╝██╔══██╗████╗░████║██╔════╝██╔══██╗    //
//    ██║░░██║██████╔╝█████╗░░███████║██╔████╔██║█████╗░░██████╔╝    //
//    ██║░░██║██╔══██╗██╔══╝░░██╔══██║██║╚██╔╝██║██╔══╝░░██╔══██╗    //
//    ██████╔╝██║░░██║███████╗██║░░██║██║░╚═╝░██║███████╗██║░░██║    //
//    ╚═════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝╚═╝░░╚═╝    //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract LCD is ERC721Creator {
    constructor() ERC721Creator("lucid-dreamer", "LCD") {}
}