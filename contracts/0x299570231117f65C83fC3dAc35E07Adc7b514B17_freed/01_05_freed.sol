// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FREEDOM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    *About the art :                                                                                        //
//                                                                                                            //
//    .*But this art piece is more than just a stunning image.                                                //
//     It's a story that will inspire you,                                                                    //
//    a journey of resilience and determination that we can all relate to.                                    //
//    I've crafted a short story to accompany the art,                                                        //
//    which delivers a long story of the protagonist's                                                        //
//    journey and the valuable lessons he learned along the way.                                              //
//                                                                                                            //
//    *Description :                                                                                          //
//                                                                                                            //
//    -Made from bitcoin code c++ and inspired by a man who changed the world map since 2009.                 //
//    -Features a fictional character with the iconic freedom glasses sign, a symbol of hope and defiance.    //
//    -Tells a story of resilience and determination that will stay with you forever.                         //
//    -A one-of-a-kind art piece that's both visually stunning and thought-provoking.                         //
//    -Perfect for art lovers who want to own a unique piece with a powerful message.                         //
//                                                                                                            //
//    *The character:                                                                                         //
//                                                                                                            //
//    Satoshi Nakamoto is the name used by the presumed pseudonymous person or persons                        //
//    who developed bitcoin, authored the bitcoin white paper,                                                //
//     and created and deployed bitcoin's original reference implementation.                                  //
//    As part of the implementation, Nakamoto also devised the first blockchain database.                     //
//                                                                                                            //
//    THANKS for taking time to read                                                                          //
//                                                                                                            //
//    ART MADE BY Kareimbenmo (K.B)                                                                           //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract freed is ERC721Creator {
    constructor() ERC721Creator("FREEDOM", "freed") {}
}