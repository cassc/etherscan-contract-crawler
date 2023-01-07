// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SCORNED-LUVER
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//                                                                     //
//    .-.-. .-.-. .-.-. .-.-. .-.-. .-.-. .-.-. .-.-. .-.-. .-.-.      //
//    '. S )'. C )'. R )'. N )'. E )'. D )'. L )'. U )'. V )'. R )     //
//      ).'   ).'   ).'   ).'   ).'   ).'   ).'   ).'   ).'   ).'      //
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract SCRND is ERC721Creator {
    constructor() ERC721Creator("SCORNED-LUVER", "SCRND") {}
}