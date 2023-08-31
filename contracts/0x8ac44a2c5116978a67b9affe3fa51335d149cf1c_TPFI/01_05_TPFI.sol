// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cultural Mosaic - Travel Portraits from India
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                                                                            //
//    .___  ___.      ___       __    __   _______     _______. __    __      //
//    |   \/   |     /   \     |  |  |  | |   ____|   /       ||  |  |  |     //
//    |  \  /  |    /  ^  \    |  |__|  | |  |__     |   (----`|  |__|  |     //
//    |  |\/|  |   /  /_\  \   |   __   | |   __|     \   \    |   __   |     //
//    |  |  |  |  /  _____  \  |  |  |  | |  |____.----)   |   |  |  |  |     //
//    |__|  |__| /__/     \__\ |__|  |__| |_______|_______/    |__|  |__|     //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract TPFI is ERC721Creator {
    constructor() ERC721Creator("Cultural Mosaic - Travel Portraits from India", "TPFI") {}
}