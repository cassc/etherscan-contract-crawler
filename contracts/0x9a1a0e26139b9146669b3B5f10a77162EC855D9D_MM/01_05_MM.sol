// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Melange of Musings
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//            :::   :::         :::   :::     //
//          :+:+: :+:+:       :+:+: :+:+:     //
//        +:+ +:+:+ +:+     +:+ +:+:+ +:+     //
//       +#+  +:+  +#+     +#+  +:+  +#+      //
//      +#+       +#+     +#+       +#+       //
//     #+#       #+#     #+#       #+#        //
//    ###       ###     ###       ###         //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MM is ERC721Creator {
    constructor() ERC721Creator("A Melange of Musings", "MM") {}
}