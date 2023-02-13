// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Just another punk derivative
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//     _______  __   __  __    _  ___   _  _______     //
//    |       ||  | |  ||  |  | ||   | | ||       |    //
//    |    _  ||  | |  ||   |_| ||   |_| ||  _____|    //
//    |   |_| ||  |_|  ||       ||      _|| |_____     //
//    |    ___||       ||  _    ||     |_ |_____  |    //
//    |   |    |       || | |   ||    _  | _____| |    //
//    |___|    |_______||_|  |__||___| |_||_______|    //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract CTRLC is ERC1155Creator {
    constructor() ERC1155Creator("Just another punk derivative", "CTRLC") {}
}