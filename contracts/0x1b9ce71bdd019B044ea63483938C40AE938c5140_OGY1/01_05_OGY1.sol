// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OGverse | Genesis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//       ____   _____                             //
//      / __ \ / ____|                            //
//     | |  | | |  ____   _____ _ __ ___  ___     //
//     | |  | | | |_ \ \ / / _ \ '__/ __|/ _ \    //
//     | |__| | |__| |\ V /  __/ |  \__ \  __/    //
//      \____/ \_____| \_/ \___|_|  |___/\___|    //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract OGY1 is ERC1155Creator {
    constructor() ERC1155Creator("OGverse | Genesis", "OGY1") {}
}