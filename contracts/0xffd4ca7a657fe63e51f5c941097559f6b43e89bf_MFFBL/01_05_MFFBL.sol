// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Final Fables - MFF
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    DNS_ERR wuz here lulz                                                            //
//    Shoutout to all of the token holders featured in this collection of episodes!    //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract MFFBL is ERC1155Creator {
    constructor() ERC1155Creator("My Final Fables - MFF", "MFFBL") {}
}