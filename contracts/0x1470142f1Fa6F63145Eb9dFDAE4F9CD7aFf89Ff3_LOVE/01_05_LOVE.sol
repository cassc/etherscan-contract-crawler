// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Its a matter of LOVE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    .-.. --- ...- .     //
//                        //
//                        //
////////////////////////////


contract LOVE is ERC1155Creator {
    constructor() ERC1155Creator("Its a matter of LOVE", "LOVE") {}
}