// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KRTT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//     __  __     ______     ______   ______      //
//    /\ \/ /    /\  == \   /\__  _\ /\__  _\     //
//    \ \  _"-.  \ \  __<   \/_/\ \/ \/_/\ \/     //
//     \ \_\ \_\  \ \_\ \_\    \ \_\    \ \_\     //
//      \/_/\/_/   \/_/ /_/     \/_/     \/_/     //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract KRTT is ERC1155Creator {
    constructor() ERC1155Creator("KRTT", "KRTT") {}
}