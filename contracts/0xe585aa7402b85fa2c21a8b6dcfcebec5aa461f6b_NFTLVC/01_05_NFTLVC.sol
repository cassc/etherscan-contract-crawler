// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFT.love custom
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//          -//////      :///////////////////////////:       //
//          :yyyyys      +yyyyyyyyyyyyyyyyyyyyyyyyyyyo       //
//          :yyyyyysss`  +yyyyyyyyyyyyyyyyyyyyyyyyyyyo       //
//          :yyyyyyyyy:--oyyyyys+++++++++syyyyys+++++/       //
//          :yyyyyyyyysssyyyyyy+         +yyyyy+             //
//          :yyyyyyyyyyyyyyyyyys++++++   +yyyyy+             //
//          :yyyyysooosyyyyyyyyyyyyyyy`  +yyyyy+             //
//          :yyyyys```syyyyyyyyyyyyyyy`  +yyyyy+             //
//          :yyyyys   ://oyyyyyo//////   +yyyyy+  `------    //
//          :yyyyys      +yyyyy+         +yyyyy+  `ssssss    //
//          :yyyyys      +yyyyy+         +yyyyy+  `ssssss    //
//          -ooooo+      /ooooo/         /ooooo:  `++++++    //
//                                                           //
//                    ://///.         ://///.                //
//                 ```syyyyy:``    ```syyyyy:``              //
//                `ooosyyyyysoo/  `ooosyyyyysoo/             //
//             `--:yyyyyyyyyyyyo--:yyyyyyyyyyyyo---          //
//             -yyyyyyyyyssssyyyyyyyyyyyyyyyyyyyyyo          //
//             -yyyyyyyyy:..+yyyyyyyyyyyyyyyyyyyyyo          //
//             .oosyyyyyy-``:oosyyyyyyyyyyyyyyysoo+          //
//                `yyyyyyyyy:  -yyyyyyyyyyyyyyy+             //
//                 :::syyyyy+:::::/yyyyyyyyy+::-             //
//                    syyyyyyyy+  `yyyyyyyyy:                //
//                    ```+yyyyysoosyyyyyy-```                //
//                       /++oyyyyyyyyy+++.                   //
//                          /yyyyyyyyy`                      //
//                          .--/yys---                       //
//                             -sso                          //
//                              ```                          //
//          `--.         .--`      ---   .--`  `-----.       //
//          :yy+         +yy:     `yyy`  +yy:  -yyyyyo       //
//          :yy+      /++syyo++:  `yyy`  +yy:  -yyyyyo       //
//          :yy+      syyyyyyyy+  `yyy`  +yy:  -yysoo+       //
//          :yy+      syyyyyyyy+  `yyy`  +yy:  -yyo```       //
//          :yy+      syyyyyyyy+  `yyy`  +yy:  -yys::-       //
//          :yy+      syyyyyyyy+  `yyy`  +yy:  -yyyyyo       //
//          :yy+      syyyyyyyy+  `yyy`  +yy:  -yyyyyo       //
//          :yy+      syyyyyyyy+  `yyy---oyy:  -yys++/       //
//          :yy+      syyyyyyyy+  `yyyyyyyyy:  -yyo          //
//          :yys++/   syyyyyyyy+  `yyyyyyyyy:  -yys++/       //
//          :yyyyys   osssyysss/  `sssyyysss:  -yyyyyo       //
//          :yyyyys      +yy:         syy.     -yyyyyo       //
//          -//////      ://.         ///`     ./////:       //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract NFTLVC is ERC721Creator {
    constructor() ERC721Creator("NFT.love custom", "NFTLVC") {}
}