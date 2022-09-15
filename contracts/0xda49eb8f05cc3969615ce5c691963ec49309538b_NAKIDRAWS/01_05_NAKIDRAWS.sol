// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NAKI DRAWS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//       \ |    \    |  / _ _|  |  |      //
//      .  |   _ \   . <    |  _| _|      //
//     _|\_| _/  _\ _|\_\ ___| _) _)      //
//                                        //
//      _ \  _ \    \ \ \      /  __|     //
//      |  |   /   _ \ \ \ \  / \__ \     //
//     ___/ _|_\ _/  _\ \_/\_/  ____/     //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract NAKIDRAWS is ERC721Creator {
    constructor() ERC721Creator("NAKI DRAWS", "NAKIDRAWS") {}
}