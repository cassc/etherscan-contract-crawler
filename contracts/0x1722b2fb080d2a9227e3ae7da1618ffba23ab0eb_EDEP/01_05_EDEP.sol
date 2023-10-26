// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Extraterrena Potentia
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//     +-+-+-+-+-+ +-+-+-+-+-+                        //
//     |E|n|d|e|r| |D|i|r|i|l|                        //
//     +-+-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+    //
//     |E|x|t|r|a|t|e|r|r|e|n|a| |P|o|t|e|n|t|i|a|    //
//     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+    //
//     |e|n|d|e|r|d|i|r|i|l|.|e|t|h|                  //
//     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+                  //
//     |i|n| |2|0|2|3|                                //
//     +-+-+ +-+-+-+-+                                //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract EDEP is ERC721Creator {
    constructor() ERC721Creator("Extraterrena Potentia", "EDEP") {}
}