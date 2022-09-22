// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test_phase_language
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//    I  I||||. I|I  ||. |I||  I. II| ||. I|I|  |.  II||  |.  I|I  ||.    //
//                                                                        //
//    I  I||||. I|I  ||. |I||  I. II| ||. I|I|  |.  II||  |.  I|I  ||.    //
//                                                                        //
//    I  I||||. I|I  ||. |I||  I. II| ||. I|I|  |.  II||  |.  I|I  ||.    //
//                                                                        //
//    I  I||||. I|I  ||. |I||  I. II| ||. I|I|  |.  II||  |.  I|I  ||.    //
//                                                                        //
//    I  I||||. I|I  ||. |I||  I. II| ||. I|I|  |.  II||  |.  I|I  ||.    //
//                                                                        //
//    I  I||||. I|I  ||. |I||  I. II| ||. I|I|  |.  II||  |.  I|I  ||.    //
//                                                                        //
//    I  I||||. I|I  ||. |I||  I. II| ||. I|I|  |.  II||  |.  I|I  ||.    //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract LANG is ERC721Creator {
    constructor() ERC721Creator("test_phase_language", "LANG") {}
}