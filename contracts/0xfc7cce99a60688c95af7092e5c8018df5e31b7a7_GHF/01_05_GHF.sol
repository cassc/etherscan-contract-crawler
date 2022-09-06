// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Grasshopper Files
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    The Grasshopper Project is an ongoing release of        //
//    information in order to uncover potential secrets.      //
//    All information released is purely hypothetical,        //
//    and no suggestions are being made by the uploader.      //
//                                                            //
//    Viewer discretion is advised,                           //
//    please be respectful of public property.                //
//                                                            //
//    Follow the Grasshopper.                                 //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract GHF is ERC721Creator {
    constructor() ERC721Creator("The Grasshopper Files", "GHF") {}
}