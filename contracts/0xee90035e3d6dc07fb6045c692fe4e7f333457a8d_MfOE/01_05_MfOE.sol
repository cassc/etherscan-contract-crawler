// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Messerfreunde
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//    www.Messerfreun.de                                                          //
//                                                                                //
//    Besucht uns auf unserer Homepage auf Insta oder einer anderen Plattform.    //
//    Wir freuen uns auf euern Besuch.                                            //
//                                                                                //
//    Zum Anfang geben wir einen NFT als OE aus.                                  //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract MfOE is ERC1155Creator {
    constructor() ERC1155Creator("Messerfreunde", "MfOE") {}
}