// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BLACKSTAR FAKEMEMECARDS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//     .----------------.     //
//    | .--------------. |    //
//    | |   ______     | |    //
//    | |  |_   _ \    | |    //
//    | |    | |_) |   | |    //
//    | |    |  __'.   | |    //
//    | |   _| |__) |  | |    //
//    | |  |_______/   | |    //
//    | |              | |    //
//    | '--------------' |    //
//     '----------------'     //
//                            //
//                            //
//                            //
////////////////////////////////


contract BFMC is ERC1155Creator {
    constructor() ERC1155Creator("BLACKSTAR FAKEMEMECARDS", "BFMC") {}
}