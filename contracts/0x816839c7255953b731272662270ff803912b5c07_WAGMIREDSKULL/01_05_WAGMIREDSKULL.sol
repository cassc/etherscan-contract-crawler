// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WAGMI RED SKULL
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    WAGMI RED SKULL                 //
//    INSPIRATION STYLE FROM XCOPY    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract WAGMIREDSKULL is ERC1155Creator {
    constructor() ERC1155Creator("WAGMI RED SKULL", "WAGMIREDSKULL") {}
}