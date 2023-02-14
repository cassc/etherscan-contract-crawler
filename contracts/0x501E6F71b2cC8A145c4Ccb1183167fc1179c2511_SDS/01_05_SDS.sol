// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sa1ntDenis Specials
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//                                    //
//     +-+-+-+-+-+-+-+-+-+-+ +-+-+    //
//     |S|A|1|N|T|D|E|N|I|S| |S|P|    //
//     +-+-+-+-+-+-+-+-+-+-+ +-+-+    //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract SDS is ERC1155Creator {
    constructor() ERC1155Creator("Sa1ntDenis Specials", "SDS") {}
}