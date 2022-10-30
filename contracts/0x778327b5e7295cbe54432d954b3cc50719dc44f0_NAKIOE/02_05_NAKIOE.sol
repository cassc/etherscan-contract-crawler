// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NAKI OPEN EDITIONS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//     +-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+-+    //
//     |N|A|K|I| |O|P|E|N| |E|D|I|T|I|O|N|S|    //
//     +-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+-+    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract NAKIOE is ERC721Creator {
    constructor() ERC721Creator("NAKI OPEN EDITIONS", "NAKIOE") {}
}