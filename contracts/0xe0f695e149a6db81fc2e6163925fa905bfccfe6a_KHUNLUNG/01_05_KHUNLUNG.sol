// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LUNGtigers world
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//     __  __     __  __     __  __     __   __     __         __  __     __   __     ______         //
//    /\ \/ /    /\ \_\ \   /\ \/\ \   /\ "-.\ \   /\ \       /\ \/\ \   /\ "-.\ \   /\  ___\        //
//    \ \  _"-.  \ \  __ \  \ \ \_\ \  \ \ \-.  \  \ \ \____  \ \ \_\ \  \ \ \-.  \  \ \ \__ \       //
//     \ \_\ \_\  \ \_\ \_\  \ \_____\  \ \_\\"\_\  \ \_____\  \ \_____\  \ \_\\"\_\  \ \_____\      //
//      \/_/\/_/   \/_/\/_/   \/_____/   \/_/ \/_/   \/_____/   \/_____/   \/_/ \/_/   \/_____/      //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract KHUNLUNG is ERC1155Creator {
    constructor() ERC1155Creator("LUNGtigers world", "KHUNLUNG") {}
}