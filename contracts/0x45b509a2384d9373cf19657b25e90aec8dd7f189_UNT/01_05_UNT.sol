// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: untimely
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    Photographer,PublisherI have 25 years of analog-digital photography documents and individual works.     //
//    I printed a Photo book. I have worked as a photography instructor for many international companies.     //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UNT is ERC721Creator {
    constructor() ERC721Creator("untimely", "UNT") {}
}