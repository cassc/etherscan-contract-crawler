// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KING HUNTER PASS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                        //
//                                                                                                                                        //
//    King Hunter Pass é uma coleção de NFT's dedicada aos alunos de mentoria do hacker Of Jaaah, especialista em segurança ofensiva.     //
//                                                                                                                                        //
//                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KHP is ERC721Creator {
    constructor() ERC721Creator("KING HUNTER PASS", "KHP") {}
}