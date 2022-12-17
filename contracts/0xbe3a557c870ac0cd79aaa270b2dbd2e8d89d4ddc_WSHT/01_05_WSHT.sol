// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: wishperhart
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    ᴡɪsʜᴘᴇʀʜᴀʀᴛ                                             //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract WSHT is ERC1155Creator {
    constructor() ERC1155Creator("wishperhart", "WSHT") {}
}