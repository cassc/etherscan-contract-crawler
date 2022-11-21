// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mutant Ape Yatch Club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                 //
//    The MUTANT APE YACHT CLUB is a collection of up to 20,000 Mutant Apes that can only be created by exposing an existing Bored Ape to a vial of MUTANT SERUM or by minting a Mutant Ape in the public sale.    //
//                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MutantApeYatchClub is ERC721Creator {
    constructor() ERC721Creator("Mutant Ape Yatch Club", "MutantApeYatchClub") {}
}