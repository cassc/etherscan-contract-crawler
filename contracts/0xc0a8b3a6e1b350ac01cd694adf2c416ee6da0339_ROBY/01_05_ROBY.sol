// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ROBY Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//        _______  ______  ______  ______     //
//       /       \/      \/      \/      \    //
//       /   R   /   O   /   B   /   Y   \    //
//       \_______/\______/\______/\______/    //
//        \      /\      /\      /\      /    //
//         \____/  \____/  \____/  \____/     //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract ROBY is ERC1155Creator {
    constructor() ERC1155Creator("ROBY Editions", "ROBY") {}
}