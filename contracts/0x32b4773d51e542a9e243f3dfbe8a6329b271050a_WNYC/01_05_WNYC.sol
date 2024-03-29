// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Walking NYC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//                                                        888          //
//                                                        888          //
//                                                        888          //
//    88888b.  .d88b. 888  888  888888  888 .d88b. 888d888888  888     //
//    888 "88bd8P  Y8b888  888  888888  888d88""88b888P"  888 .88P     //
//    888  88888888888888  888  888888  888888  888888    888888K      //
//    888  888Y8b.    Y88b 888 d88PY88b 888Y88..88P888    888 "88b     //
//    888  888 "Y8888  "Y8888888P"  "Y88888 "Y88P" 888    888  888     //
//                                      888                            //
//                                 Y8b d88P                            //
//                                  "Y88P"    ::Ariel Saldana          //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract WNYC is ERC721Creator {
    constructor() ERC721Creator("Walking NYC", "WNYC") {}
}