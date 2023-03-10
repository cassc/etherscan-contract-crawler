// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mbapepe Genesis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//      __  __ _                                     //
//     |  \/  | |                                    //
//     | \  / | |__   __ _ _ __   ___ _ __   ___     //
//     | |\/| | '_ \ / _` | '_ \ / _ \ '_ \ / _ \    //
//     | |  | | |_) | (_| | |_) |  __/ |_) |  __/    //
//     |_|  |_|_.__/ \__,_| .__/ \___| .__/ \___|    //
//                        | |        | |             //
//                        |_|        |_|             //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract MBP is ERC721Creator {
    constructor() ERC721Creator("Mbapepe Genesis", "MBP") {}
}