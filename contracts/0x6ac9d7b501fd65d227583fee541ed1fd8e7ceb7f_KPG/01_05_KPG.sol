// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Keisuke Pass Genesis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    No Utility. Please HODL and Gachiho.    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract KPG is ERC1155Creator {
    constructor() ERC1155Creator("Keisuke Pass Genesis", "KPG") {}
}