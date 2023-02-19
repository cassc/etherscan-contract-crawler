// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Midnight Drive
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                              `````'==`@#[email protected]@RRQ#L% %[email protected]@8BBBBBBBBU    //
//                                        -     ````""-"`@@U"@@[email protected]@%-%[email protected]@[email protected]@M    //
//                                         ]  , "`````"-"#$M[@@EbQ#[email protected]@@@RBBBBX8G    //
//                                         ]  ``-``````'[email protected]`@@[email protected]=`"="[email protected]    //
//                                         ]  ` [email protected]@[email protected]@M[@@[email protected]=`````"`[email protected]@@@RBBBBERM    //
//                                         ]  ` @@@MQW&&pm#U"@@[email protected]=`1``"="[email protected]@@RBBBBEMC    //
//                                         ]  ` @@@@@@@@@`@U"%@ER4%F==%R[=``"[email protected]@@@[email protected]    //
//                                         ]    e#g#E##@@@bM`[email protected]@@#L="]B="-``[email protected]@[email protected]`    //
//                              "^^>*-     ]   [email protected]@[email protected]@MbQ%@##P`=7#===`="[email protected]@@#[email protected]"    //
//                             ,.     `    ]   ][email protected]@[email protected]@Q"=N`=]R" ``[email protected]@[email protected]@{`    //
//                           .,Q]Q    '`   ~-. <[email protected]@@@*[email protected]@@BBBBK%-``]B=``-M`"@@[email protected]@@%`    //
//                           "@#@m    ``   ] `  ```"``)Q`""[email protected]@==" " "=- [email protected]@@Q`    //
//        8BkERRTBPEkRRF       @"|    `-   """G   ````4KRBBRpw,"=O==M="""==`"""[email protected]@bBRM="`    //
//        @E%4EE%ARK#KK*              ,`   ]     ` ```[email protected] - ```=-=#bBEQ`=`    //
//        [email protected]@@0`=`` ` -=,,,,,,,, Q,,       ]     ,`..."@@#[email protected]@@@@@@m    ``""[email protected]#BMM""     //
//        .,^a#@m . ----"--==--=====]C`````]` ``` ` ` M=`)=, ""%G> `%@'"``"`    -"%#[email protected]"]M%    //
//         [-"`,",],)~-=``%Q%| []@  @Q,,,,,],,,,,,)@@@M=%,=%"[email protected]@@-QM"""`[email protected] =#5#MM #,#    //
//         /-. .``-````M ,{="3m"Ql&w&@\"--^"-.,,Q~~;.,.-]~%QQQ="""`""` [email protected]@@O"=QQQ{==M=%wa    //
//        ""```"7- - `````[email protected][email protected]@[email protected]@@5"===`=7#QQ)M=[@M,Q7QQQQQQQ ="=""*"M"""""[email protected]\``"    //
//        =%M====%=aQ,{&[email protected]@MQ="~  @Q ]m,86emQampBRRRRRBBBBpw4QQ#%%%%%QQQQQ%[email protected]@@[email protected]@@%QQ    //
//        ``````[email protected]@[email protected]@@[email protected]@[email protected]@@Q$Q#QBBRBRm8BAb&&[email protected]@@@@[email protected]@@[email protected]@@    //
//         ``-```47"^^[email protected]#@@R8BRWWQQQQQQQQQQQQQMMM=JRR******@*T|||""T"I"T"T"""""%@@@@@[email protected]    //
//        """"""`==` -'Q "-'..'   """"=~~4M*~% ``[email protected]%]@%p  )#      `     Q%@"] ]@@@@@@@@    //
//        ````.-'--"=\{\`    `        V^`'"->=^`|Q`+&,==*^"""""""">=C]",,,,w&&-+#@###@[email protected]@d    //
//        .===--~~<"`-Q#`               `  -\$==     , `^```` ` /=g,.[ @  --~ ]@[email protected]@@[email protected]@@@    //
//        ======`````>%N    "`=""-        "#\7 "       `         @*@*"       @[email protected]=M    //
//        ``,>==>``,,.                    `QQe                ---eem        @@@@@@@R#R####    //
//        ``-"""""""'```                   `*                             [email protected]%@@@Q%@@@@@@@    //
//        `````',-"---````                             ---==--o-=)-g=-.. ,-&&QQQ""MMMMM%@M    //
//        ===`"`"""=~==-``                                      `-,"``'`^ `-,[email protected]@@@@[email protected]@RK    //
//         ``""  ~--..``""   ~                                ``""""`` ```-"[email protected]@@@[email protected]@@[email protected]    //
//          =---..``""  ~~-                                        ==%=%wweQQQQQQ5"Q7QQQQ&    //
//                ``````     ``             ``` ```             ``""""*=>eweq,,,,```^`"""=    //
//                  "`   ==      ^==           ````` -,---.       ``""""7%%me&q,,,,,^""^""    //
//                                                `````""==-==M%@@@@@@@@%%eee-,,,,,,^`""""    //
//                                  `""             `````"" ====5G==7G=5==7"[email protected][email protected]@    //
//                                                                                            //
//    ---                                                                                     //
//    asciiart.club                                                                           //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract MidnightDrive is ERC721Creator {
    constructor() ERC721Creator("Midnight Drive", "MidnightDrive") {}
}