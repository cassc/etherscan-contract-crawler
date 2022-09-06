// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fucking Coral
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                          ,                                          //
//                                                                                                                     //
//                                 ,$$#y                              @$5Rm$Q$g                                        //
//                                                                                                                     //
//                                 $Qg1w%                             %@[email protected]&L        @&b                            //
//                                                                                                                     //
//                          ,@>    @[F|,7F                             "@$$WrJK$       $Y5$Q                           //
//                                                                                                                     //
//                         /$,JL  ]&|yA|QF                              '@@&{C]@[      @@L"@@           ,              //
//                                                                                                                     //
//                        ,$,\*Q  $g7AQw&[                               ]@[2L]4$     @NF ]g$          7LCJ            //
//                                                                                                                     //
//                     $r^L$L"-ur $L~|F$6L          [email protected]%Qg                ]@$&][email protected]@   ,@@TF$lWF    g1,   @'-]K           //
//                                                                                                                     //
//                     "1%  ;-.&L Wl;Cfil[         [email protected]               [email protected]@p$W$$  ,@@&C44]&    $F jC /gr [email protected]           //
//                                                                                                                     //
//                      ]@`&," $& $L w]\$$  pw     [email protected]|[email protected]               ]@&[email protected]@ ,[email protected]}-$MK     1\" Y&%hL"aK           //
//                                                                                                                     //
//                       |~g  +.} $K-],\)W $$$$    ]@@{ nBC    [email protected]@K$      @$${}[email protected]@}C^[email protected]@`     Jg|,- , g;g            //
//                                                                                                                     //
//                        [email protected]~,&L]@ \"`R$&&[email protected]     [email protected]   /$D/Q$$     [email protected]@$+]1M%" [email protected]@       ]VL| ~ TL^$            //
//                                                                                                                     //
//                        ]|$;;\[email protected] $y`y\Z"j$Y$[      $Mg"$]L ][email protected]]Q$      @[email protected]`Djwz][email protected]$        @LCLu`,"Q$L            //
//                                                                                                                     //
//                         $%ZVZ-,&'$gA \P[Y[QF  ]@[email protected][[email protected]       ]@$$\  QCj$$        gBgL `"u $&             //
//                                                                                                                     //
//                          %$Q L Q%@$g,' }[email protected]&%p '@Lj"h ]nA(@P[[YQN         @gPW;`$]R$|       ]@$fL/A,A=&@             //
//                                                                                                                     //
//                           \@${+w>M%&Q  >w lM$g "$$"[[email protected] uW9$Q/          [email protected]@$P\ AV$$       @M"7 7r"M&&              //
//                                                                                                                     //
//                            'V$g$&}`@)C`.v+g|B&$g &@/jGY ]'L$|$            $$&gw*[email protected]@$L     [email protected] \7"[email protected]@               //
//                                                                                                                     //
//                   w~         -"[email protected]$aglZ 7M,|[email protected]@@$ wL'!J],$L    ]$#*    $$$k}D]}@$&    /&$PQ;I,D&@                //
//                                                                                                                     //
//                  ]]{`y            "&@[email protected]%  M&DI$BC$$| u],'w[Y&    $$$w9   ]$&@g(PY2$&  ,gR${@>[email protected]@                 //
//                                                                                                                     //
//                  ]W-,']        4nw,  "&[$lJ`R5Cj#$]&2 -" j^"W%C   [W]l&&  ][email protected] ,h[|$%&&[email protected]`{[email protected]                  //
//                                                                                                                     //
//                   @&}~ $r     @g"W*L   "[email protected],M%@[email protected]"],+}*24$   $L&PL$  ]@@&$gup}y$$&[email protected][~"[email protected]   ,]]w            //
//                                                                                                                     //
//                   [email protected]]w    [email protected] w%y    ]@@L,`{$QW|}g~   &j|$$$, &$jq{$  [email protected]@&$}m[- $/~$$7qZgZ$`    L,rJL           //
//                                                                                                                     //
//             ]g][email protected]"-,Q,  '[email protected]$wZ$l     B&@wrm'$wO?,.~,r&"g$$$g]{j,[email protected]&[email protected]$"U] `L>][email protected]$$k`     |`1-]@           //
//                                                                                                                     //
//              ][email protected]~&[email protected] ]-WTb. [email protected]$gj F&,   [email protected]" +-$,V]\ .M"[email protected]@`[email protected]$[W}$A7M`[email protected]`       [,+"C,L   gMm    //
//                                                                                                                     //
//               *[email protected]@[email protected]@[email protected]$l,[email protected]&Qe`,*`]*$)|xPZ"L^4 "c]>=L,*[email protected]#$Op"$$jAA$Q'[2Ag5P]P`         @ww l4&[email protected]$]@    //
//                                                                                                                     //
//                     `"*[email protected][email protected]' CZj{$L*'=~-"~ '~L"]"QwT"``FFJ,Fj&$$$P&@, )ljUVQ7)qKgy$*` ,=+,      L`L;4&[email protected]@    //
//                                                                                                                     //
//               ]@$$W      '"[email protected]@@@Z+Q-r]]F\y",g,w, }@"f- |>*X.wK]&&@Wj{J `}}~$Mu$$$&N   ,@-*[email protected]    $`K 5|[email protected]"     //
//                                                                                                                     //
//                @/$&@Qg,      `"*[email protected]@[email protected][email protected][email protected]@6g$&[email protected]@ws`yp\x^C}wj&[email protected]{]  PL*|[email protected]&J$$-   #*.*$Q  gMl\.Y\[email protected]`        //
//                                                                                                                     //
//               [email protected]]wjA$&@[email protected],,, ``""""*****[email protected]@[email protected]@@@[email protected],JlyAC$%$]@|L|$ y|[$j$QU$&    @'A]$Bg$&$4^$/@@"           //
//                                                                                                                     //
//               BgZ$4$"gr\&%[email protected]@[email protected]@$Ng,     ,[email protected]@[email protected][email protected][email protected]@[email protected]@@[email protected],[@i{J&hQg$  ,@\w,4P&@%P^$$g$P             //
//                                                                                                                     //
//                 "9&[email protected][email protected][email protected]&$N%[email protected][email protected]$&[email protected]@[email protected]@[email protected]@@@@@@[email protected]&V&#LL#|w+Q&QD#[email protected]%[email protected]'"4$*[email protected]$N               //
//                                                                                                                     //
//                       ""**[email protected]+$:$C{&[email protected]&@@%[email protected]@@[email protected]@@[email protected]$$L$)|$Qg[[m}MQ$J,&/[email protected]$&@gM                 //
//                                                                                                                     //
//                              ,,@$gy]/Z^j~"b"%[email protected]*[email protected]@@[email protected][email protected]@@@@[email protected]@[P}L$[gj|$RWDQy",$'[email protected]"                   //
//                                                                                                                     //
//                       ,,gg$#B$$$G" "g r$,Zs.]p-D`$b)[email protected][email protected]@@@@$D${Ql$$w|$JP%$$$H[[]wG|Q[[email protected]"`                     //
//                                                                                                                     //
//                g$$AR$&&&$l FZ,[email protected][email protected][email protected]@[email protected]][email protected]$Q%[email protected]@@@@@[email protected][email protected]@|[email protected]@F[$$AW&P|$[[[email protected]"                         //
//                                                                                                                     //
//                *[email protected]~C$,l%$g$&M*``   ``"*R&#[email protected]@@$#@[email protected]@[email protected]@@@[email protected][email protected]&[email protected]@&&[email protected]$$FKF)}]!]UK                           //
//                                                                                                                     //
//                  `*MNW$$l&NP^"                   '''""[email protected]@@@@@@@@$N&[email protected]|$|Q|PQQ|QAPJYKLQ[                           //
//                                                                                                                     //
//                                                         ]@@[email protected]@$$B&[email protected]$$$Pg$w&$Q[`g @,$                           //
//                                                                                                                     //
//                                                          [email protected][email protected]&N&RPRP*""    `"``""**""""                             //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
//                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CORAL is ERC721Creator {
    constructor() ERC721Creator("Fucking Coral", "CORAL") {}
}