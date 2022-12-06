// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 305kore
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//    ┏━━━┳━━━┳━━━┳┓              //
//    ┃┏━┓┃┏━┓┃┏━━┫┃              //
//    ┗┛┏┛┃┃┃┃┃┗━━┫┃┏┳━━┳━┳━━┓    //
//    ┏┓┗┓┃┃┃┃┣━━┓┃┗┛┫┏┓┃┏┫┃━┫    //
//    ┃┗━┛┃┗━┛┣━━┛┃┏┓┫┗┛┃┃┃┃━┫    //
//    ┗━━━┻━━━┻━━━┻┛┗┻━━┻┛┗━━┛    //
//                                //
//                                //
////////////////////////////////////


contract kore305 is ERC721Creator {
    constructor() ERC721Creator("305kore", "kore305") {}
}