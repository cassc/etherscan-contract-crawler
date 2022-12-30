// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: editions by cleytonb
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                    ` [email protected]@@&ggww,,,, ,          ~,,,                          ++    //
//                     ,[email protected]|LLLiMML{|j"Li]{'`jg^yw~,,,,,'                           //
//                   |     `'"""***MM&L`LL|,L ;,~, |'*  {l #` $$ l$','j%mr=~wg,,,,,       //
//                         ,y;,         |   l|lMl;|'  l.&L,gF]lF]lF,, @F @@ $lllllllll    //
//                       [email protected]$i        '  y`:@$$l&LLy :. |$%M`  `'"""***~..#llllllllMM    //
//                   ,,g/[email protected]| L`  ,@@"' ,F/[email protected]@iLi; }|L,  ,$%%@k               `    //
//                  ][email protected]$*     %F  ,a`LgM$$$$$$$&MlllLL;[email protected]@@w$T!iF      `         @    //
//                  **%[email protected]     L ''' `"'''''''''`` `"*&l#[email protected]@$MLy,     /        ,@$    //
//                  `L#$$$$l$  *`                          `*%[email protected]@@@@k            @@$    //
//                @,,@$$$$$$F`                                 *[email protected]@k  `        #[email protected]@    //
//    *Www,,ylL   [email protected]`                                     *j$%@@ / |lllliL;[email protected]@    //
//           `    [email protected]`                                         $]T j   l||!|||@[email protected]    //
//               '"[email protected]                                            ]T `` ,,  '*j%@[email protected]    //
//               +;l|ji                                              ,, ' ,'**~  ,F!l*    //
//                |lLlF                                              [email protected]&%Wgggg    //
//                l%%F   ,,yyw,,,            ,  ,,                   ]|MMM%%[email protected]@@@#@@@    //
//              '[email protected]`"     ' |||"[email protected]@@@@@MM*******MMkmwg,,            jw|w|]M,jj| L$FM*    //
//              jll|&'j;|`wjwL|lLjF 'ji||||l||+,,   || "$$WiMw,,,    ][email protected]$M&@[email protected]    //
//              |lM    '*' '***lL$,  |@k|lllL'l#MWlL|| j$  ''"******'   T**WLwwIQL$$$$    //
//              $l!L     j''!'''(k   '$%|||L|||  |||||=#`             |L]ggylllTj%[email protected]    //
//              l$lM,     `''  ,F     "F ''''''||| |  jF           ;    @$$$$$$$$$$$$$    //
//    |liLL     ilLL  ` ~,,,,wr`       "W            ,F                #$$$$$$$$$$$$$$    //
//    ||||||llljWlFF         +            "***Mxwwr*"                 ]$$$$$$$$$$$$$$$    //
//      ||+| |'|||l         `           L                        ,    @$$$$$$$$$$$$$$$    //
//        |  |    L         |,,    ,,, ,                            ,@$$$$$$$$$$$$$$$$    //
//             '|`L     ,[email protected];;;[email protected]|      '                 '    ,@M%MMMM$%&@@[email protected]$$$$$    //
//                `    ll$T*''`'**'%WLlylyWy,                  |L||||||||||||||||, `"j    //
//                `    '|l"ML''"*L=|L;||||llllL     |,         !||||||||||||||||l|||||    //
//                 L  '| '     =s.   ,,|l*|lMT     ||'    +    |||||||||||||||||||||||    //
//                  |  "'  .,            '||    ;||||    |'    |||||||||||||||||||||||    //
//                          [email protected] |  |L!' ,|||||  ||l`     ||| |||||||||||||||||||    //
//                    ;     ,|{lll|'   ' |ly||||''||||r`       ll||||  |   || |           //
//                    "y;g Ll$$ll$lL,  |\|Wl&!lL;lll'          `"*,||          |          //
//                      'M$$%@[email protected][email protected]%[email protected]$$llM*'            [email protected]@l                       //
//                        *"""*%@[email protected]@[email protected]&$M*'            ='%@@L ]QlL                      //
//                      "   `    `''''''       ||,,w|'`     ]FLL  Mlr                     //
//                     L ' `'              |||iM"`|' ``      'wg`' ]L                     //
//                    F  ;@M%L            |T'`   +' '      ,"' '`' '$,                    //
//                   `  +  '"     |' ,~:y&L'L             *"L' ; ,""gg$&,                 //
//                    |          [email protected]%N%@@ %@@   `          `~lL\[email protected]@@@ %@@L"*''             //
//                           a  ,[email protected]@@NMr ***%,         ,,,~ [email protected]@@[email protected]%@[email protected][email protected]@[email protected],|        //
//                  ,    '  {,   '       !M  ",,;   ,, =,[email protected]@@@@@%@    'MMM*ML`[email protected]&"|     //
//               ,g$|||   ,@F     '     '',{ ,@w',,,[email protected]@@@@@@@[email protected],,.'    - ,,  ""**Mk,     //
//      ++~     l|||||F` /@MF           "-| [email protected][email protected][email protected]@[email protected]@[email protected][email protected]" ''               ,#@    //
//       '"'' ;|||F`    /@**`       , ',j%[email protected]@[email protected]@@@@@$$F'`',~=~       ,,         "%    //
//     |'' 'L j|l` ,   #`  ,,;;,,[email protected]@@[email protected][email protected]@@[email protected]@@@@[email protected]@@M"  `/l`   ,w      .             //
//      '  `  ]lF  `  /lL;[email protected][email protected]@[email protected][email protected]@@@@[email protected]` ",[email protected] ,        '          ,[email protected]$    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract ECTB is ERC1155Creator {
    constructor() ERC1155Creator("editions by cleytonb", "ECTB") {}
}