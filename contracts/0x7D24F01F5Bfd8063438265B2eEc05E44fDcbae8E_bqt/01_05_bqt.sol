// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: bouquet
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//       `    `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  .gMN,.  `             //
//                                                                                `  7N,              //
//          `                             .                                        .M"?WN,            //
//                                         ]                                       ,b  J\/N.          //
//       `     `  `  `  `  `  `  `  `      N    `  `  `  `  `  `  `  `  `  ` ..,    (""'  -b          //
//                                     `   M.                               -$ .Ta         M.         //
//          `                              M~                               M.   (h.       M`         //
//                                  `      M~  `                         JYSd]    ,N,     .F          //
//       `     .JMMMa,`  `  `  `        `  M      `  `  `  `  `  `.gHHN, J] ,M,     Ua. .(F           //
//            ("     ?N,          `       .#                 .,  J"    M_ M,  "       ?"=             //
//                     Th                 .F                  ?h.F   .gB  ,N                          //
//                      JN.               d\           ...     ,M]   ?`    d]                         //
//                       -N.             .#         .#"7?7TN,   .W,    N.  .N                         //
//                        (N             d\        ($       ?N    4b   .N, [email protected]                         //
//                         vb           -F               ../ Jb   -#N.   _"^                          //
//                          Wp         .F              .#^   [email protected]`.h                                //
//                           H2       (Ng+..          .F     .#                                       //
//                           .M,    .M^    ?YN,       .N    .M^  .`                                   //
//                            .N, .d"         ?Wa.     (BQgM"  .(!                                    //
//                             .NJ^              TN,.        .-D                                      //
//                              .M,                .TMg....J#"                                        //
//                                Wp                                                                  //
//                                 ?N.                                                                //
//                                   Ta.                                                              //
//                                    .Tm.                                                            //
//                                       ?9a,.                                                        //
//                                           ?"""!`                                                   //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract bqt is ERC721Creator {
    constructor() ERC721Creator("bouquet", "bqt") {}
}