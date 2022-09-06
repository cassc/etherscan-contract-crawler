// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hammmer Time
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    .__                                                     //
//    |  |__ _____    _____   _____   _____   ___________     //
//    |  |  \\__  \  /     \ /     \ /     \_/ __ \_  __ \    //
//    |   Y  \/ __ \|  Y Y  \  Y Y  \  Y Y  \  ___/|  | \/    //
//    |___|  (____  /__|_|  /__|_|  /__|_|  /\___  >__|       //
//         \/     \/      \/      \/      \/     \/           //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract HMR is ERC721Creator {
    constructor() ERC721Creator("Hammmer Time", "HMR") {}
}