// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NEO STREETS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    ██████╗░███╗░░░███╗    //
//    ██╔══██╗████╗░████║    //
//    ██║░░██║██╔████╔██║    //
//    ██║░░██║██║╚██╔╝██║    //
//    ██████╔╝██║░╚═╝░██║    //
//    ╚═════╝░╚═╝░░░░░╚═╝    //
//                           //
//                           //
///////////////////////////////


contract DM is ERC1155Creator {
    constructor() ERC1155Creator("NEO STREETS", "DM") {}
}