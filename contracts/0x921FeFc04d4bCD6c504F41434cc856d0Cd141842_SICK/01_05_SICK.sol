// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SICKNFTBRO VOL.1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//         _______. __    ______  __  ___     //
//        /       ||  |  /      ||  |/  /     //
//       |   (----`|  | |  ,----'|  '  /      //
//        \   \    |  | |  |     |    <       //
//    .----)   |   |  | |  `----.|  .  \      //
//    |_______/    |__|  \______||__|\__\     //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract SICK is ERC721Creator {
    constructor() ERC721Creator("SICKNFTBRO VOL.1", "SICK") {}
}