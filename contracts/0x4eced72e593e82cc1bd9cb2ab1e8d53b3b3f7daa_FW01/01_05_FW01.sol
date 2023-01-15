// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FRAMED WORLD
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//     __ __          __ __        __  __     __      //
//    |_ |__) /\ |\/||_ |  \  |  |/  \|__)|  |  \     //
//    |  | \ /--\|  ||__|__/  |/\|\__/| \ |__|__/     //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract FW01 is ERC1155Creator {
    constructor() ERC1155Creator("FRAMED WORLD", "FW01") {}
}