// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Macy's Thanksgiving Day Parade
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                    |`                                                                               `X`              //
//                   ^m>                                                                             `^[email protected]=`            //
//                  ,amS_                                                                             `|,|.             //
//                  Immmj`                                                                                              //
//        'r???????cmmmmmt???????>,  w7,Ljwoz;  `+nSm{*'      `;7ywSn?' cP'    '=Iawy7;`  ;P!        ;P^ -?jwj|`        //
//          :|5mwwmmwwmmmmmmmmZL~    @@Qn!~!\[email protected]>;~>[email protected]   `[email protected]\!~;=}[email protected]~  ;NQS>;[email protected] [email protected]~      ;@Q`[email protected]=~^bQ~       //
//             ~iSmmmmmmmmmSc;`      @@-     `[email protected]|      |@| 'Q#,        [email protected]@~ [email protected]`       ,WQ,`QQ`    -QQ' [email protected]*   'y^       //
//               >mmmmmmmmmL         @R       [email protected],      ,@S [email protected]~          [email protected][email protected]#          `,` [email protected]   `gQ,  `yQQXu>`        //
//              -ZmmmmommmmS,        @D       [email protected],      '@m [email protected]~          [email protected]~'@N           ``  [email protected] `[email protected]~      `~*[email protected]       //
//              7mmy>, '+fmmt`       @D       [email protected],      '@m 'Q&,        \@@~ [email protected]`       'RQ:   [email protected]@?   `ga     QQ       //
//             ^Z|,       ,*5>       @D       [email protected],      '@m  `[email protected];[email protected]~  ;BQa=;~;[email protected]'    `[email protected]@\     [email protected]^~^[email protected]       //
//             _`           `_`      mc       >m-      .m*    `;zymSf|, \m'    '>{amoJ!`       \@x       'LymyL.        //
//                                                                                            >@q                       //
//                                                                                           [email protected]`                       //
//                                                                                           `.                         //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MTDP is ERC721Creator {
    constructor() ERC721Creator("Macy's Thanksgiving Day Parade", "MTDP") {}
}