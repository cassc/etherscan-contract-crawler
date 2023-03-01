// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Raffle for Beanz #9605
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//     +-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+    //
//     |B|E|A|N|Z| |R|A|F|F|L|E|#|9|6|0|5|    //
//     +-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+    //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract raffle is ERC721Creator {
    constructor() ERC721Creator("Raffle for Beanz #9605", "raffle") {}
}