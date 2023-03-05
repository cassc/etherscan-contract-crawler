// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BIC BLUE WORLD ENTRY TOKEN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    BIC BLUE WORLD ENTRY TOKEN 1-100 of 100 of 100,000,000 of the rest of our lives.    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract BICBW is ERC1155Creator {
    constructor() ERC1155Creator("BIC BLUE WORLD ENTRY TOKEN", "BICBW") {}
}