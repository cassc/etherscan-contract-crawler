// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OddWritings
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//         elizabethan sonnet    as a        word-unit palindrome       //
//                            g  -  - a                                 //
//                            g  -  - b                                 //
//                            f  -  - a                                 //
//                            e  -  - b                                 //
//                            f  -  - c                                 //
//                            e  -  - d                                 //
//                            d  -  - c                                 //
//                            c  -  - d                                 //
//                            d  -  - e                                 //
//                            c  -  - f                                 //
//                            b  -  - e                                 //
//                            a  -  - f                                 //
//                            b  -  - g                                 //
//                            a  -  - g                                 //
//                    Love    our confines, value not        Fate       //
//                    above   the limit lives                supply.    //
//                    Youth   enraptured vow the             state      //
//                    dare    never disallow this            lie.       //
//                    Truth   in advertisements              bold       //
//                    where   pledge those promises some     praise,    //
//                    betrays old feeling bought and         sold.      //
//                    Sold    and bought, feeling old,       betrays    //
//                    praise  (some promises those pledge),  where      //
//                    bold    advertisements, in             truth,     //
//                    lie.    This disallow – never          dare       //
//                    state   the vow enraptured             youth      //
//                    supply. Lives limit the                above.     //
//                    Fate,   not value, confines our        love.      //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract ODD is ERC721Creator {
    constructor() ERC721Creator("OddWritings", "ODD") {}
}