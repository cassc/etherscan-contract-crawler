// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Calmness
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//      _ )   __|   \ |   __|   \  |  _ \     //
//      _ \  (_ |  .  |  (     |\/ |  __/     //
//     ___/ \___| _|\_| \___| _|  _| _|       //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract BGNCMP is ERC1155Creator {
    constructor() ERC1155Creator("Calmness", "BGNCMP") {}
}