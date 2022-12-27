// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Metro Area
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//     __ __        _              ___                    //
//    |  \  \ ___ _| |_ _ _  ___  | . | _ _  ___  ___     //
//    |     |/ ._> | | | '_>/ . \ |   || '_>/ ._><_> |    //
//    |_|_|_|\___. |_| |_|  \___/ |_|_||_|  \___.<___|    //
//    Elfilter/2022                                       //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract Area is ERC721Creator {
    constructor() ERC721Creator("Metro Area", "Area") {}
}