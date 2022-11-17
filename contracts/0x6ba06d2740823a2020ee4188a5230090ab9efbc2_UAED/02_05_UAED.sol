// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Urban Archetypes Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                  .                                                                                                                      //
//                                                                 ^-.                                                                                                                     //
//                                                                 ^+.               '^``^^'                                                                                               //
//                                                               . `_.               '^``^^'                                                                                               //
//                                                               i?--?_^             '^^^^^'                         :_;                                                                   //
//                                                            `+?---__--]i.          '^``^^'       .'.''.            ;?;                                                                   //
//                                                            `<------__?l           '^^^^^'       .^^^^.         '>-___+_^. .`^^^^^^'                                                     //
//                                                            `<-__--_-_?l          .`^^`^^'       .^^^^.        ''>?-___-`. .```````'                                                     //
//                                                """"".      `<-------_?I   .`^^^^^^^^^^^^'       .^^^^.       ._]-__----??;.`^^^^^^`                                                     //
//                                               '_--?_"      `<-------_?I    `^^`^^^^^^^^^'       .^`^^.        +-__----__-I'^^^^^^^`                                                     //
//                                    .''.'.    '>--_--<^     `<-------_?I    `^^`^`^^^^^^^'       .^^^^.        +?---__-__-I`^^^^^^^`                                                     //
//                                    '^^^^`.   '<-__-_+"     `<-------_?l.  .`^^^^^^^^^^^^'       .^^`^`'''''   +?-----__--I`^^^^^^^`                                                     //
//                                    '^`^^^    '<---_-+^  ```"+--_-----?i`^llllll:`^^`^^^`^''''``..^`^``^^`^`.  +-----_--_-I``'`'````  .'                                                 //
//                                    '^`^^^    '<---_-+"  `^^,+--_----_?i`^+--_-?i`^^^^`^^`^``"""`'""^`^^^`^`.  +---_-_----I`<-?--;``. ;{:                                                //
//                                    '^`^^^    '<---_-+^  `^`,+--_----_?li[_---___-^`"`^^^``',+------!`'^^^^`.  ~---------_I`<-__-;``. ;}, ..                                             //
//                                    '^`^^^    '<---_-+"  `^`,+--_----_?!i----__---^I!``^``^:--_-----?!`^^`^^``^_?_--_----_I^~--__I`^,?]_]<^^'                                            //
//                                    '^^``^    '<-----+"  `^^"+-_-_----?!i?--_--_--";!``^^^,<-------_-_I'^^`",`^_-_--_-_---I^<-__-I``I----~,^'                                            //
//                                    `^^^`"`^`'"~-----+"  ``^,+-_-__---?!i?------__>]]>^`,";_-----_--_?l"^`^>?;^---_----_---?-_-_-I'`<----_l`'                                            //
//                                    `^`^II!^``"+---_-+"..^^`"+-_-_----?!i?------_+>?->^^??----_----__--[!'`i-il_--_--_-_----__-_-I'^<----_I`'    .' .......                              //
//                                    '^":+--:"`"~--_--~,<?---i<-_-_-_--?!i?---__--_i-->^^_---_--_--_---_]l'^i---__--__------__----I'`>?_---l^'    ;_:^^^^^^^'                             //
//                              .`'`'``,<?-__?+""+-_---_~_-__-+_---_----?!i?-------_i-?>``---------------?l'^i------------------_--<!i+-----I`'..  ;+,^^"`^^^'                             //
//                              '`^^`'^+?-__---i^~-_-_-_-_---_-----_-_--?!i?--------_--_:^---------------?l'^i----------------_-------__-_-_I^';[-------]!'^^'                             //
//                           .'I!>:',]--_---_--_---_---__----__----_----?!i?---------__-:`---------------?l'^i-------------------------___--l`,--_--__---_,`^'                             //
//                        '`"."+??I',]_--------------------------------_?!i?_-----------:^---------------?!'^i?_-------------------------_-_l'"-_--_-____-"`!<!i!ii;                       //
//                        `^.:]-__]i"?-_------------------------------_-?l!?------------:^---------------?l:_??_-------------------------_-_lI>-_-__---__->:l____--i.                      //
//                        '^`,]--_?!^]_--------------------------------_?l!]_-----------:^---------------]l,]----------------------------_-_li-_--_------_-l!----_-i.                      //
//                   .'!>>i:!i-----<i--------------------------------__--~+-------------:^---------------]l,-----------------------------_-_Ii---_-_---_---I!---__->^^^`.                  //
//                  ^':_--+l--_-_----------------------------------------------------_--:^---------------?l,--------------------------------~~--_-__------_++-------i^`^                   //
//                  ``>?__--__----------------------------------------------------------:`---------------]!;--__-----------------------------___--_--------____-_---<^`^.                  //
//                  `'>?_------------------------------------------------------------_--+<----------------?--_------------------------------_-------------_--_--_--?<^^^                   //
//                 'll<-___--_-_----------------------------------------------------_----_----------------_-_-__-----------------------------_--__-_--------_--_-_--+!l!;.                 //
//                 ^--_--_-----------------------------------------------------------------------------------------------------------------------------------------------^                 //
//                 '<<<<<>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>><<<<<'                 //
//                                                                                                                                                                                         //
//                 `,:,,^                ',,,,"      `:,,,,,,,,,,,,,"^.           .:,,,,,,,,,,,,,,,,"'                   ^,,,".               ",,,`                 ",,,,.                 //
//                [email protected]'               [email protected]@@p;    '[email protected]@@[email protected]@[email protected]@[email protected]@@$$Bm):.       }@@[email protected][email protected]@@[email protected]@Bq1^ .             >[email protected]@@@f'             :[email protected](^ .            [email protected][email protected]                //
//                 v%[email protected]               ([email protected]$p:    [email protected]@@[email protected]@$$J;      [email protected]@@BoOQ00000000p&[email protected][email protected]             <[email protected]@@@@B|..           ,[email protected]@@@b}'            ;[email protected]@$W_                 //
//                 c%$$BX.               |[email protected]:    [email protected]@@(          ;[email protected]@@%-     ][email protected]@C;          `r&@@@Bl           [email protected]@[email protected]{            ,[email protected]@@[email protected]@d-           ;[email protected]$$W_                 //
//                 v%@$BX.               ([email protected]$d:    [email protected]$|.          .)#@@@a,    ]@@[email protected]:           ;[email protected][email protected]?          [email protected]@@c'[*[email protected]{           ,[email protected][email protected]%@@@@q-         ;[email protected]$W_                 //
//                 c%@$BX.               ([email protected]@d:    [email protected]@@|            [email protected][email protected]*l    [email protected]@L:          .}[email protected]         >[email protected]@BX  .|[email protected]%{          ,[email protected]@$o1(*@@$%m~       ;[email protected]$W_                 //
//                 c%@$BX.               ([email protected]:    [email protected]@('.         [email protected]@@@x     [email protected]@@bvrxxxxxxxxpM$$$#['         [email protected]@Y    [email protected]@#}         :[email protected]#{ ^[email protected]@BZ!.    ;[email protected]$W_                 //
//                 c%@$BX.               |[email protected]$$d:    [email protected]@@z]][]]][?]z#@[email protected]@@[      [email protected][email protected][email protected]@@@@@@[email protected]@8q1` .       ,[email protected]^ .    [email protected]$o]        ,[email protected]$$#{   [email protected]@@Bm"   ;[email protected]$W_                 //
//                 ([email protected]@$C`               [email protected]"    [email protected]@@@[email protected]@@@[email protected][email protected][email protected]}.       ?$$$$LI``^^^^^^^^Ic%[email protected]&>      [email protected]@$UI````````[email protected][email protected]  .    ,[email protected]$$#{     ^r%@$B$m" ;O$$$M_                 //
//                 [email protected][email protected]?  .       .   ;[email protected]@$8x     [email protected])(()))[email protected]$8n^         [email protected]$L:            ;[email protected]%]    '[email protected]@[email protected]@@@@@@@@@@@B$a~. .   ,[email protected]$$#{       ,[email protected]$BC>[email protected][email protected]_                 //
//                  [email protected]@@p+.           [email protected]`     [email protected]@|.   .  `[email protected]@d~        ?$$$$L:            `[email protected][email protected]  .^[email protected]@[email protected]@@k!     ,[email protected]$$#{         [email protected]@@%[email protected]@$W_                 //
//                   }%@@@@Q{:.    .^_Y%@[email protected]@0'.     [email protected]@(.        [email protected]@@$u`      [email protected]:          '>[email protected][email protected]%|  "[email protected]@8z`            ][email protected]$$k:    ,[email protected]$$#{           ;[email protected][email protected]@@@W_                 //
//                   .;z#@@[email protected]@[email protected]@@@BZ~        [email protected][email protected]@|.         ,[email protected]@@a>     ][email protected][email protected]&[email protected]@@@@k-. "[email protected]$BC`            .')%@@@o,   ,[email protected]@$#{            [email protected][email protected]@W_                 //
//                      '<[email protected][email protected]@[email protected]$WZn-".         '[email protected]@@B/.          '[[email protected]@@%z,   ][email protected]@@@@@@[email protected]|I.  "[email protected]@0'               '[email protected]$Ba:  :[email protected]@@M)              .<[email protected]@W-.                //
//                           ''^""^``                .'''`              .''`'`.    '''''`'''''''''''.     .  '`'''              .    '''`'.   ''``'.                 ''''.                 //
//                                                                                                        .         .                   .                             .                    //
//                     .|#ai       [oM#**#Mou,.       '_C#8WC-     +Ma|       -dM/. ^x#M###M##M#v"a#######o####0[MMJ'   .  .1oWc`^oM#M##W*uI    >##########q_   `tp8%WX>    .              //
//                     <[email protected]$L`     .}[email protected]%&[email protected]$bl  . `[email protected]%8&8%[email protected]"  [email protected]&f    .  [#@r' "[email protected]%8888888Y"M888&[email protected]&888#[email protected]     _M$U" "%@[email protected]@m!  >[email protected]] "[email protected]@8&&[email protected]^                //
//                    "[email protected]#@]      }B8/     [email protected];  [email protected]@Mj`   `f&@L; [email protected]       }#$f. ^[email protected]! .      .     [#@f       [email protected]   lhBOl  ,[email protected]'   [email protected]; <@8n         `[email protected][    ']q>                 //
//                    [email protected]?c%W^     }B%f     [email protected]*{ IW$ai       >_.  ]@&j       [#@j. ^c$di              }#$r       '[email protected]}  `p$q>   ,8$J^  . '[email protected]@? <@%u         [email protected]^                         //
//                   'h%c';kBJ     }B%f    . [email protected]] u%%1             [email protected]&uIlIlllI|#$f. ^[email protected]+""""""'       }M$r        "[email protected]<'p$h~    "8$J^    `[email protected]%? <$%c""""""^. ^[email protected]@ot<"                      //
//                   vBdl  )8%]    }B8r"","[email protected]"`[email protected]%!             [email protected]@@[email protected]@@@[email protected]@@@j. "[email protected]@[email protected]@@@@@n`      }M$r         ;[email protected]@W]     "[email protected];,",Iu%@U, <[email protected]@@@@@@@b>  "v&@@@@MZvi .                //
//                  <@&/....qBp"   }%[email protected]@[email protected]@[email protected]&j^ .UB%_             [email protected]((((|(([email protected] ^[email protected]][}[[}!.      }M$r          [email protected]@B[      ,[email protected]@@@@@@$8z,  [email protected]%L]}[[]}-^    .I]nq%@$BQ,                //
//                 `[email protected]%%[email protected]%u   }B%Y?][[email protected]    ?&@0.            ?$&f       [#$f. ^[email protected]              }M$r           [*@r       ,8$m[?]?-<"    >@%n           .     'id$%v.               //
//                 f8Br:::;:;wBb<  }B%f   '0$8x.   n$BC`     ^nWz, [email protected]&j       [#$f. ^[email protected]  .          }M$r           [*@f       ,[email protected]`          <$%u         .)l     . ]$BJ'               //
//                ih$#..     ;B$U^ }B%f    .d$&f '  (@$BJ~I>zB$$x` ?$&j       [#$f. ^[email protected]<><<<<<i.     }M$r           [*@j       ,[email protected]^          <$%J<<<<<<<<"v%@Bb}l"ivB$o]    .           //
//             . ^[email protected]@i.      [email protected]&).{B%j     [email protected]&t..  ^v&[email protected]@@BWJ: . [email protected]       }#@f. ^[email protected]@[email protected]@@@@@o,     }M$r           }*@j       ,[email protected]^          >@[email protected]$$$$$$$Bt <b&[email protected]@[email protected]@8d;..               //
//               ',:^.        .,;".':;'      .,;,'      ^Ii;       ';:`       ',;^   ^;:,::,;:,:,      '::^           ',;^        ,:"           '::,,,,::,:,`     ,!>I`                    //
//                                   .                    .                .                                                                                                               //
//                                      ;------l.']_.    '+}`  I?--_----+`  I?;    +?---_--?>'~~'    :?I.   ^>[]l.   '<---?_:.  `}I     `-> '<--?--?<`                                     //
//                                      j%mvvu0%0!(8O`  `X%j. .?vccd%Qvcx:  f&f    nccJM*Xcc/lOmI    |@f' lOWwcYaWv' Im8YcvQWq> <@&x`   iBZ.IZ%Yzccc/;.                                    //
//                                      f%f' .^uM? +BZ""X8[.       YW]     .tWt       ~dp,   I0O;    |@f'iBbI    ]%m";Z#l   ]oc^<B#8q> .iBO';O8;                                           //
//                                      f%*pppak[.  l&pC#[.        U&[     .tW/       ~dd,   I08hkkkk*@f'Z8?      c#1;Z#i""!U%/'>@wi0M/'[email protected]';ZBkdbp0_                                      //
//                                      f%x:"";v8(.  lkh-.  .      U&]    . rW/       ~dd,   lOZ>"","[email protected]'L%f      [email protected]#[email protected]  >@p''fWq<@O.;OWi^^^^.                                      //
//                                      f%t'  .tBv^  ,0qi          U&[     ^oh_       ~dp,   lOZI    |@f'.m%v'  ;M&j ;ZMI ./@c^ >@p'  [email protected]@0.;ZWI        .                                  //
//                                     .t#M&&&W*x^   :0Z>         .L*}.-p&&&k<        -ddI   lQZl    (Wf'  iOW&WMr'  ;Q#l  .(#C:i&m^    )W0'IQWM&&WWh-                                     //
//                                                  .    .                 .                        .     .               .     .      .      .      .                                     //
//                                                                                                                                      .      .                                           //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UAED is ERC721Creator {
    constructor() ERC721Creator("Urban Archetypes Editions", "UAED") {}
}