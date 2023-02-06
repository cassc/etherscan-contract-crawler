// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DBD by CEMO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     ██████╗███████╗███╗   ███╗ ██████╗     //
//    ██╔════╝██╔════╝████╗ ████║██╔═══██╗    //
//    ██║     █████╗  ██╔████╔██║██║   ██║    //
//    ██║     ██╔══╝  ██║╚██╔╝██║██║   ██║    //
//    ╚██████╗███████╗██║ ╚═╝ ██║╚██████╔╝    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract DBD is ERC721Creator {
    constructor() ERC721Creator("DBD by CEMO", "DBD") {}
}