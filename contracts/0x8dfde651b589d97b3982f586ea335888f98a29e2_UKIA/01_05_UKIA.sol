// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UNIQIANA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//                   UU     UU NN    NN IIII  QQQQQQQ  IIII    AAA    NN    NN    AAA                       //
//      ##     ##    UU     UU NNN   NN  II  QQ     QQ  II    AA AA   NNN   NN   AA AA      ##     ##       //
//        ## ##      UU     UU NNNN  NN  II  QQ     QQ  II   AA   AA  NNNN  NN  AA   AA       ## ##         //
//    ####KIANA####  UU     UU NN NN NN  II  QQ     QQ  II  AAAAAAAAA NN NN NN AAAAAAAAA  ####KIANA####     //
//        ## ##      UU     UU NN  NNNN  II  QQ  QQ QQ  II  AA     AA NN  NNNN AA     AA      ## ##         //
//      ##     ##    UU     UU NN   NNN  II  QQ    QQ   II  AA     AA NN   NNN AA     AA    ##     ##       //
//                    UUUUUUU  NN    NN IIII  QQQQQ QQ IIII AA     AA NN    NN AA     AA                    //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UKIA is ERC721Creator {
    constructor() ERC721Creator("UNIQIANA", "UKIA") {}
}