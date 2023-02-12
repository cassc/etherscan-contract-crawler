// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: カタカナレア
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBNMRRQBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBg"!rJ3kBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBRj!'  ^[gBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBN?     !$BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBNQgRo?<!,```       '|QBBBBBBBBBBBBBBBBBBB    //
//    [email protected]"     ,[email protected]@65u|!"'     -_^!c>`       "BBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBe      ~0BBBBBBBBBBBBBBBNqvkNM)-'         "[email protected]'        $BBBBBBBBBBBBBBBBBBB    //
//    [email protected]>      [email protected]>:^PBBgY~'.`     -'  `=eM?    ``''-EBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBB&!   'FgBBBBBBBBBB4/- [email protected]%E5ePDgK^    '  "TZK#&@NBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBQ.  >QBBBBBBB&ET  .^mBBBBBBBBBBBBBBBBBBBN.    ^MBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBB,  |&BBBQE3!,  [email protected]|    ,BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBB'  =0&l!`    '[email protected]     RBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBM>   '_       rbBBBBBBBBBBBBBBBBBBBBBBBBBp"    ,NBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBL           "#BBBBBBBBBBBBBBBBBBBBBBBBBQo-    /0BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBB}`       `"ZQBBBBBBBBBBBBBBBBBBBBBNBBBG"  .:!ZQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBKEw/!!=>dNBBBBBBBBBBBBBBBBBBBBBBBNBbL`_7U$NBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KTAKANARARE is ERC721Creator {
    constructor() ERC721Creator(unicode"カタカナレア", "KTAKANARARE") {}
}