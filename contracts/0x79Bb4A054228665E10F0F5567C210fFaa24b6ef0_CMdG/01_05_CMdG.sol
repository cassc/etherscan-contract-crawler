// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoMADONNE de Guadalupe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                 //
//                                                                                                                                                 //
//    CryptoMADONNE de Guadalupe was created exclusively as a tribute to "Nuestra Señora de Guadalupe", Queen of all Spanish-speaking peoples..    //
//                                                                                                                                                 //
//                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CMdG is ERC721Creator {
    constructor() ERC721Creator("CryptoMADONNE de Guadalupe", "CMdG") {}
}