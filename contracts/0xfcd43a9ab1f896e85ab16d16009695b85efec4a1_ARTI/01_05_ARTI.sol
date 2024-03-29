// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ArtIsTry Intelligence
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//         .oo         o  o        ooooo                o         o         8 8  o                                        //
//        .P 8         8  8          8                  8         8         8 8                                           //
//       .P  8 oPYo.  o8P 8 .oPYo.   8   oPYo. o    o   8 odYo.  o8P .oPYo. 8 8 o8 .oPYo. .oPYo. odYo. .oPYo. .oPYo.      //
//      oPooo8 8  `'   8  8 Yb..     8   8  `' 8    8   8 8' `8   8  8oooo8 8 8  8 8    8 8oooo8 8' `8 8    ' 8oooo8      //
//     .P    8 8       8  8   'Yb.   8   8     8    8   8 8   8   8  8.     8 8  8 8    8 8.     8   8 8    . 8.          //
//    .P     8 8       8  8 `YooP'   8   8     `YooP8   8 8   8   8  `Yooo' 8 8  8 `YooP8 `Yooo' 8   8 `YooP' `Yooo'      //
//    ..:::::....::::::..:..:.....:::..::..:::::....8 ::....::..::..::.....:....:..:....8 :.....:..::..:.....::.....:     //
//    :::::::::::::::::::::::::::::::::::::::::::ooP'.:::::::::::::::::::::::::::::::ooP'.:::::::::::::::::::::::::::     //
//    :::::::::::::::::::::::::::::::::::::::::::...:::::::::::::::::::::::::::::::::...:::::::::::::::::::::::::::::     //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ARTI is ERC721Creator {
    constructor() ERC721Creator("ArtIsTry Intelligence", "ARTI") {}
}