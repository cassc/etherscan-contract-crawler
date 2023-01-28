// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Everything & Nothing
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//     ___  _ _  ___   _    ___  ___  ___   ___  _ _  _ _  _ __    //
//    |_ _|| | || __> | |  | . |/ __>|_ _| | . \| | || \ || / /    //
//     | | |   || _>  | |_ | | |\__ \ | |  |  _/| ' ||   ||  \     //
//     |_| |_|_||___> |___|`___'<___/ |_|  |_|  `___'|_\_||_\_\    //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract TLPEN is ERC721Creator {
    constructor() ERC721Creator("Everything & Nothing", "TLPEN") {}
}