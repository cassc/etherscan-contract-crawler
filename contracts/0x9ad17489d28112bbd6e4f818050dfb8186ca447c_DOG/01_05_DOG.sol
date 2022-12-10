// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DANCE OF GRACE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//          :::::::::   ::::::::   ::::::::     //
//         :+:    :+: :+:    :+: :+:    :+:     //
//        +:+    +:+ +:+    +:+ +:+             //
//       +#+    +:+ +#+    +:+ :#:              //
//      +#+    +#+ +#+    +#+ +#+   +#+#        //
//     #+#    #+# #+#    #+# #+#    #+#         //
//    #########   ########   ########           //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract DOG is ERC721Creator {
    constructor() ERC721Creator("DANCE OF GRACE", "DOG") {}
}