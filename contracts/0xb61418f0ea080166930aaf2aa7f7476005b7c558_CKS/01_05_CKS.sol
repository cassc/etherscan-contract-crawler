// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cutie kitties
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//    Two cute kitties representing two cute brothers on their way to the web3    //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract CKS is ERC721Creator {
    constructor() ERC721Creator("Cutie kitties", "CKS") {}
}