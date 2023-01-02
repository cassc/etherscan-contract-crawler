// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Streetkid’s Garage
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                            //
//    First contract of 2023. 3d printing and 3d files focused. Holders of these tokens will be eligible to design and create 3D files with full ownership of the file and will have their print sent to them physically. I will update the metadata to reflect the full 3d file stored on the blockchain     //
//    Cam smith 01/01/2023                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKG is ERC721Creator {
    constructor() ERC721Creator(unicode"Streetkid’s Garage", "SKG") {}
}