// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: munira_contract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                 oo                       //
//                                                          //
//    88d8b.d8b. dP    dP 88d888b. dP 88d888b. .d8888b.     //
//    88'`88'`88 88    88 88'  `88 88 88'  `88 88'  `88     //
//    88  88  88 88.  .88 88    88 88 88       88.  .88     //
//    dP  dP  dP `88888P' dP    dP dP dP       `88888P8     //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract MUNI is ERC721Creator {
    constructor() ERC721Creator("munira_contract", "MUNI") {}
}