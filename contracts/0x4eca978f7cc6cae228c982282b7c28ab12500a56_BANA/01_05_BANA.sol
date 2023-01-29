// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: This is a Banana
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//    This is a banana, Ode to the Banana, Banana = ART. ART = $$$                            //
//    Big dollar Banana. APE on BANANA                                                        //
//    https://i.seadn.io/gcs/files/f462b490d2d176e8ff671515a0707a9a.jpg?auto=format&w=1000    //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract BANA is ERC721Creator {
    constructor() ERC721Creator("This is a Banana", "BANA") {}
}