// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: V1NWOLF
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//         :'*=*Li"!||[email protected]$|%@$L&]%QgQj$ll&LlF{''*` ':.!   > ,[email protected]@[email protected]@@@@@]"L   , .]@    //
//        L, ]{,[email protected]$|%&@[email protected]$E4Q]$J$$$g$$$%M= L,.`"'*:M,,L|]R$|$$$$$M&@$%[email protected]@w,gg||        //
//        `,,g*'jg#[email protected]$&&%[email protected][email protected]@M*[email protected][email protected]$$g$$&l||LL{LF -5iQ,Ql,&|l$$$&$$$$$lr$%[email protected]@@'  '     //
//         @[email protected]}*[email protected]@[email protected]@@`[email protected]$&[email protected][email protected]@@@@@@g,===:.lZljlj&&$|$,@@W$l|j$g$$NLg,ww    //
//        P%Qg,g/[email protected][email protected][email protected]@@$]@@[email protected]$$$g|i$#@@@@@[email protected][email protected]@@@@,~`,` llT*M&F%&@M%l$jwg=W*"*-        //
//        `[email protected]$][email protected]%[email protected][email protected]&&g&%@@g%[email protected][email protected]&@@@$i$%[email protected]@@@@@@@''yk^k!|ljQ|NWx%g$|}|g~, '`        //
//        [email protected] "}[email protected]&[email protected]@MWW}&@$$$$W1$$r]@@@M*$L,[email protected]@@@@@W%ig$Ml" |$WL|A$&[email protected]%$T' `gg        //
//        I'"'  <|[email protected]@@@l*"C&@[email protected]@$$li|F [email protected]@@L $L]@[email protected][email protected]@@@@@|#{&@[email protected]|%[email protected][email protected]$Q'j&ML {"NNjgg    //
//        @\@@[email protected]@@j$$L/%Mm&]@[email protected]@[email protected]@@@  ]@@$`,$L'[email protected]@@@@|s|[email protected]$lA,$l$$M}'j]$jC. } ||%|    //
//        |T%$$$&$MlL#i*|[email protected][email protected]$%@@[email protected]$  ]@@@@[email protected]@@@[email protected]@@@@lW%L$F#[email protected][email protected]$&]@$gML  l||$    //
//        ggj#||[email protected][email protected]@N$&,l$&@&@[email protected]$"  ]@@@@@@[email protected]$,,][email protected]@@@[email protected]@@@@@[email protected]@@K,LL|,'`,L    //
//        [email protected]@L jM#@[email protected]@@@@&$$y,jgW$jW$j ,,]@@@@RLl]@@@@[email protected]@@M$L$Q}&,[email protected]@[email protected]%@    "]%gr 4F'    //
//        @$,J , '`***[email protected][email protected]@@[email protected];#[email protected]@$1L$ @@@@@@@@@@$&[email protected]@@W*M&&M&[email protected]@,,,,, *M ]@@    //
//        1M   L'  \l! ' &gQ$&@[email protected]|@%']@@@@@`"}@@@@@@@[email protected]$$|Q$$$Ql=, [email protected]@[email protected]{]}w F,[email protected],]    //
//        glgx'' '  **  ^Y&*j$l%WiTF'`$,/"@@[email protected]@uL ]P$][email protected]@W&@[email protected]%[email protected],g$$L*$y]@/ '-&[email protected]%M    //
//        M$R&[email protected]$M%{]$Nygy[|$$$F  "*`  @@@@$$,,[email protected]@@%[email protected]@$FT#[email protected][email protected]@[email protected]@R$\@$%[email protected]$C'&@ "    //
//        @[email protected]@[email protected]*"$`L,]$g j&$g|&    ~   [email protected]@@@@} B%[email protected]@@[email protected]@@[email protected]@@@@[email protected]';j$4$$ggg    //
//        [email protected]$&jWFMCyk,g[$BP $$&R$`   j*` ;[email protected]@@@@L [email protected]@@@@@W#`[email protected],[email protected]@@@@M}]{|,jZj/@[email protected]&@@$$    //
//        [email protected]*"*|,|$`   /][email protected]$%"]/[ !;, ;[email protected]@@@@@,[email protected]@@@@@$F }[email protected]$F][email protected]@@@@@[email protected]%F$*$%@[email protected][email protected]    //
//        @Bl   #@vgQ%$4L&yFk/[email protected] [email protected],    "&@@[email protected]@[email protected]@@@@J$, ][email protected]@[email protected]@@@&FR$ ''C"@&[email protected]@*    //
//        gQMNW,i%[email protected]$]I$|j~*@@@F'  ,,L   ']@@@@[email protected],][email protected]@P$MT"[email protected]&@Tl]M`*F*\sML     @Cw"$P]    //
//        @@@ww '-"[email protected]@BBm&@[email protected],,,ygr"mggg][email protected][email protected]$g ]@@@@Q%,g}[email protected]@@[email protected],x+Fy,sp][email protected][email protected]"           //
//        @%F" rrL#[email protected]@@@@l|[email protected]***j&Ngg$NMM]@@@$$$ ]@@@Q$$  l&|[email protected][email protected]$$L| jTJ%B="  `            //
//        [email protected]@W%@@@C   ]'[email protected]|gL,,[email protected][email protected]@@L$]@@@llF |[email protected]@@*T  -'f &,        4g%    //
//        [email protected]@g&@@@@C"]w j'}|&m|l%$jWj$$$$$F']@[email protected]@Z=>$lMTl$#[email protected]' ,[email protected]      - $L    //
//        @@@[email protected]@@gN"@]F' , ',,  lQ&G "][email protected]@$$&||']@[email protected]@K$%|TlLY|[email protected]$ ||'=,[email protected]@, ,,,,[email protected]    //
//        [email protected]@**[email protected],,"]@,gF   '|,l,L |,[email protected][email protected]@"   @,]$|[email protected]@@$yg"$$$$$$|$$"[email protected][email protected]    //
//        |%@&M%$P%*F |[email protected]' ,~ ,#[email protected]*L]$W$$$M  . [`[email protected],]@@[email protected]@[email protected][email protected][email protected]  yL @$M$',    <m`    //
//        L|,$#$*[email protected] [email protected]%,F,   j'y$$gy|"`*||$$$FL,y= ,@ ]R$%&@[email protected]@@@@[email protected];j$ [email protected]`#'|@@   #      //
//        |L|||BgL'lYJk,]g,l, ]L jgg%AM#&@@@@@@$Mf o$$ j|&&&[email protected]@[email protected]$$'$gC @F]$F& |[email protected]    //
//        M=|,'jD**RQL%[email protected]    $&[email protected]${@[email protected][email protected] `  .]k|| ;[email protected][email protected][email protected]|[email protected]/$$`]@ LL       //
//        @@$$LgM   , ,g''% *, ]@[email protected];`!'|[email protected]@@pmnj >j$'|' ;@"[email protected][email protected]@L]$ ]  [email protected] r#'j'L''`    //
//        @@@@@@[email protected],  T*"  '$g$L}$"MQW"  :[email protected][email protected]]$" ~j`l!||#,  ]@@[email protected]@@@|@$|F,@F|@',;$$$" ,    //
//        [email protected]@@@@[email protected]@*}  "  $#*`,]k "$L  =$Q$Q' @@ '$'*'w|F `%[email protected]$$&@FjM${ lg&@  g$$$L.=J    //
//        %@@@@[email protected]$ ,L. `]gWl   |$ | "V  ]@$lLg$Z$$NFM;l$ , !#[email protected]@[email protected][email protected]&@[email protected][email protected]  ,[email protected][email protected]     //
//        @%@[email protected]@@$  ,, |W$L  ']       ` '4,wj$'$YW$|$` | ;@@@[email protected]@@$$l$Ll$M   '}llM$QML     //
//        *%@1   |[email protected]&,$j]@@N$C" "YL"$* ,   ,r";]@@@lMi$   ,[email protected]@[email protected]@@@[email protected][email protected]@g$L,-;|,&@[email protected]@@ggg    //
//        Q$$   ||[email protected]@|$ ]@@@MP , "4F*$"$g /@g |[email protected]@W,,|Wl#@@@[email protected][email protected]@[email protected]@%%@@[email protected][email protected]@$$$E"    //
//        [email protected]@@[email protected]&Lr""%T``,'"`! F<~'"$|2QKL""$%%N$WiLlWi|, '[email protected]$&Kj$$yi|,"*"]M%@[email protected]$$%m    //
//        &@[email protected]@[email protected]@@@m$;[email protected]`   `` `4&YE]$%[][email protected][email protected][email protected][email protected]$${ `   . ,|$${T*''y    //
//         "<%[email protected][email protected]@+g$$/,            ,g$$%@F*[email protected]@@wgp&&[email protected]$L]@@[email protected]%$L; ,[email protected]@&[email protected]@@@U"    //
//        =  (@@@@@@@|d$$$l        |g&[email protected]@[email protected][email protected]@[email protected][email protected]$$$$$w#@[email protected][email protected][email protected],l$$&j$&@&$`     //
//        ,, ;[email protected]@@@@@@@@B$L     :|A&M ,~]@[email protected]@[email protected]@[email protected]@@&[email protected][email protected]@@@@[email protected][email protected]|Wg$$$&$#F      //
//        "@[email protected][email protected][email protected]@@@L      ``''  `]@[email protected][email protected]@@@@@&[email protected]@@[email protected]@#&%[email protected]$l&[email protected]@&&[email protected][email protected]  ,    //
//        ]@@gggwq!' "G""*[email protected],k `` @@[email protected]%@[email protected]@@@@@@@[email protected]@[email protected]@@@[email protected]@@@@[email protected]$&[email protected]$F,,,}    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract VNW is ERC1155Creator {
    constructor() ERC1155Creator("V1NWOLF", "VNW") {}
}