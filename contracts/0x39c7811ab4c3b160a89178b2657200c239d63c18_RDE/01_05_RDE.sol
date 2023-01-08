// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rob Dawkins Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//    --[[                                                                                    //
//    ██████╗ee██████╗e██████╗eeeee██████╗ee█████╗e██╗eeee██╗██╗ee██╗██╗███╗eee██╗███████╗    //
//    ██╔══██╗██╔═══██╗██╔══██╗eeee██╔══██╗██╔══██╗██║eeee██║██║e██╔╝██║████╗ee██║██╔════╝    //
//    ██████╔╝██║eee██║██████╔╝eeee██║ee██║███████║██║e█╗e██║█████╔╝e██║██╔██╗e██║███████╗    //
//    ██╔══██╗██║eee██║██╔══██╗eeee██║ee██║██╔══██║██║███╗██║██╔═██╗e██║██║╚██╗██║╚════██║    //
//    ██║ee██║╚██████╔╝██████╔╝eeee██████╔╝██║ee██║╚███╔███╔╝██║ee██╗██║██║e╚████║███████║    //
//    ╚═╝ee╚═╝e╚═════╝e╚═════╝eeeee╚═════╝e╚═╝ee╚═╝e╚══╝╚══╝e╚═╝ee╚═╝╚═╝╚═╝ee╚═══╝╚══════╝    //
//    eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee    //
//    --]]                                                                                    //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract RDE is ERC1155Creator {
    constructor() ERC1155Creator("Rob Dawkins Editions", "RDE") {}
}