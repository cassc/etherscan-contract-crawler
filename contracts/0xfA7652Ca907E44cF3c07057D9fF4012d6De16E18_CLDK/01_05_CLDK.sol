// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cold Key
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                    //
//                                                                                                                                                    //
//    This is your Key Pass to unlock Project Blue, a decentralized web3 music label backing independent artists, Twitter in bio for more details.    //
//                                                                                                                                                    //
//                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CLDK is ERC1155Creator {
    constructor() ERC1155Creator("Cold Key", "CLDK") {}
}