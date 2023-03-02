// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FlysAlpha Contract of The Future
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    FlysAlpha Contract of The Future    //
//                                        //
//                                        //
////////////////////////////////////////////


contract Fly is ERC1155Creator {
    constructor() ERC1155Creator("FlysAlpha Contract of The Future", "Fly") {}
}