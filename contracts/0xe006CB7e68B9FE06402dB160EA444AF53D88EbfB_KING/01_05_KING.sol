// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Murphy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//          (`-.            _ (`-.      //
//        _(OO  )_         ( (OO  )     //
//    ,--(_/   ,. \ .---. _.`     \     //
//    \   \   /(__//_   |(__...--''     //
//     \   \ /   /  |   | |  /  | |     //
//      \   '   /,  |   | |  |_.' |     //
//       \     /__) |   | |  .___.'     //
//        \   /     |   | |  |          //
//         `-'      `---' `--'          //
//                                      //
//                                      //
//////////////////////////////////////////


contract KING is ERC721Creator {
    constructor() ERC721Creator("Murphy", "KING") {}
}