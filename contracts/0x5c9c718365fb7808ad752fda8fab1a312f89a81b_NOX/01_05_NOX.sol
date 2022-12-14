// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Noxverse
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                           //
//                                                                                                                                                           //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&[email protected]&&WWWWW&&WWWWWWWWWWWW&&&&&&&&&W&&&&&WWWWWWWWW&&&&&&&&&&&&&&MRRQBR&W&&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&[email protected]&&&&&&&&&&&&@[email protected]&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]&WWW&WWWWWWWW&WWWWWWWWWWWWW&&&&&&&[email protected][email protected]    //
//    [email protected]`[email protected]&&&WWWWWWWWWXGAm&WWWWWWWW&&&&&&&&[email protected], `[email protected]    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&WWWW&BHH%  }[email protected]&&XPPAk8na]3auzzPXW&W&&&&&&&&&&WW&@OkPB0`   [email protected]    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&WWWWWRHH0   ,[email protected]&&WPAApC2cv?i}tvcc71l2bPWW&&&&&&WW&m02zgB$`    [email protected]&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&MHH0     [email protected][email protected]??+~`  `"zv}77"+8X&&&&&W&PClcuXBq`     [email protected]&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&@BHq      [email protected]&WWpevj"""}711+'  |c-`+z}?C&&&&@XblclCPqX"      CRWWW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&DHZ      >&BO][email protected]?z``>+""ijtt^  +\  +zvaXW&&Fzvcc22cTe   ,,``qRWW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&@BO``,`>-`SOTA%3ccccz0ASz|r|`   `|1|  ``  ~"z%&@A2ccccccc8l \z5I>` GQWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWW&&WWWWWWWWWWWWWWW&&&&WDQ" ^lI$z"2qxl]5lcccczqP0z?>\i0%nkOIlc2Ck$wO&&8cccccccc0k``\>}v_``[email protected]    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&@&@BA  ,zPga>|mPncccccccczPMPbnqCae][email protected]  `+st` +mPPGGOXWWWWWWWWWWWWWWWWWWWWWWWWWWWW&WWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&WPgm&v'^^ie:  x0qg3cccccc2ae+,                \ic2zccccCIg}    ,^` _:jxqAGXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&    //
//    WWWWWWWWWW&@@@@@@@@&WWWWWWWWWWWWWWWWW&&gr`e}\zI?`  |S ^xIcczazi,                      ,"7zzC8`0i    `+s}>0XWWW&WWWWWWWWWW&@[email protected]@&WWWWWWWWWWWWWWWWW&    //
//    WWWWWW&[email protected]@&XXW&&&WWWWWWWWWWWWW&&&WW&Xqc}+,      z   lqa+-                            ,?0z`}l    `'':5$kXWWWWWWWWWWWWWW&&&@[email protected]    //
//    WWWWMRDMXmmmmmmmGGOXWWWWWWWWWWWW&&&&&&&&&WAn?_`,`   "  _i_                                  |"`",   `^">?0AmWWW&&[email protected]@WWWWWWWWWWW    //
//    W&DBDmOmmmmmmmmmOGmWWWWWWWWWWWWW&&&&&&&&Pus>^`\z+   ,                                           `      "z8qOWWW&&&&&[email protected]    //
//    @[email protected]&&&&&WGgu>``,|e]+     ``           `ij"~`                          \`_PXWXPXWW&&WWWWWWWWWXmmmmmmmmmOPPGXMMWWWWWWWW    //
//    WWWWXXmmOOmmmmmXXXWWWWWWWWWWWWWWW&&&&&XOIt\,~'~_ql~``,+t?'          +v_+lli'                  `     "00gGWWWWW&&&WW&&WWWWWWWXmmOOOOGGOmmXW&&WWWWWWW    //
//    WWWWWWWWWWXXXXXWWWWWWWWWWWWWWW&&&&&&&&&m]222"`|+ua"~|++i}`          }+i??jc2c~              '1vj"`   [email protected]@WWW&&W&&&&&WWWWWWWWWWXXXXXWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&PPOA?aP%cl+^"""?t\      ,>'  |s?j??jjc3v-            rcj?tt\  ^FXWWWWWWWW&&&&&&WWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&WWWPP&klx}\""+??|       ,?vi^`}1jj?j???le"           +cjjt"v_  iGWWWWWWWW&&&&&&WWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&&&XFw?\"}}?j"`        "jjli,}cjjj?j??7et`         `"??j}>l\ `nXWWW&WWW&&&&&&&WWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWW&WWWWWWWWW&&WW&&&&&&&&&&&&&Wgs_:1}jj+`      `>"`+??ct`"l1j??jj?j2s`          ~??j""c` "PWWWWWW&&&&&WWWWWWWWWWWWWWW&WWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWW&WWWWWWWWWWW&&WWW&&&&&&&&&&&&mv"`+cjjt-      ~um%,`"?j1+ '7ljj?j??jz+           |j??_1+ `nWWWWWW&WW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&&WT"~`1rj?_      "FDHQI` \+?1"``"cvj?jjjjl` `        `+??+_l` >&WWW&WWWWW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&Ol"`\c?j|      r&HHHHRC,  `:~~` `>1vjjjjj" :|        ,i?j_1| `[email protected]&&&&WWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWW&[email protected]&&&&&&&&&&&WA1" |7?+`     1MHHHHHHR0\    `}|  `>?1j?j}` ||        |?j"++  nWWWWWWW&@@[email protected]&WWWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]@&WWWXXWWWWWW&&&&&&&&Wqs| |j?\     i&HHHHHHHHBml,   ,2ni, `~+tji`  +\       `}?+>i  ?mWWWWXXmOmXmmmmWMDDMWWWWWWWWWWWWWWWWWWWWW    //
//    [email protected]@WmmmmmmmXGGmWWWWWW&&&&&&WCs\ 'j"     |PHHHHHHHHHHHRGl,   +hPa"` `--   ,t`       >j}>}  [email protected]@WWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWMDXGGmmmmmmmmXGmWWWWWW&&&&&&&Xn1' `+'    ,qBHHHHHHHHHHHHHBme~  ,aWMPx"`     ++       \j}"+  `[email protected]@WWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWW&@@mGPPGOmmmmmmmXWWWWWWW&&&&&&&XIr'  \`    vDHHHHHHHHHHHHHHHHBMgz|`+ABHDO]+-  'z`      ,t+?>   tmWWWWWXmOmmmmmmmGPPPXWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWXXmmmmmmmXXWWWWWWW&WW&&&&&&m]j,       ,%HHHHHHHHHHHHHHHHHHHHBMPCewmBHBDXZx?e"      `}+l'   \AWWWWWWWXmmmmmOOmmXWWWWWW&&WWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&W&&&W&&&Ozt`       >GRRQDMMMMMMMMMDDDQQDQQQDQRQMRHHHHHH&nv      `}7r     uXWWWWWWWWWWWWWWWWWWWWWWW&&WWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&W&&WPr"`       +G&@MQBBHHHHHHHHHBRRBHHHHHBBRRRRBBBHR82_     ,1t`     +mWWWWWWWWWWWWWWWWWW&WWWWWWWW&&&&WWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&P>~`       }[email protected]     |+`  ``  'AWWWWWWWWWWWWW&WWWWWWW&&&&&&&&&&WWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&&0:,`       +XHHHHHHHHHHRMPn+```,`` ```````` `,_"zcl`    ,   `?j   IWWWWWWWWWWWWWWWWWW&WWW&&&&&&WWWW&&&&WW    //
//    WWWWWW&&WW&&&&WWWWWWWWWWWWWW&&&&&&&&&&&&&&I          \AHHHHHHHBQOn+````,\a````````````   `cs2'        ~aI`  +XWWWWWWWWWWWWWWWWW&&WWWWWWWWWWWW&&&&WW    //
//    WWWWWW&&WW&WWWWWWWWWWWWW&&WW&&&&&&&&&&&&&Wv           zRHHHHBMk}````````,\````````````   "lj2|        r2z+  _GWWWWWWWWWWWWWWWWW&&WWWWWWWWWWWWWWWWWW    //
//    WWWWWW&&WW&&&&WWWWWWWWWWWW&&&&&&&&&&&&&&WXi  ^_    ", ,ABHB&n|```````````` ```````````  \1ril"       |er1z  `hWWWWWWWWWWWWWWWWW&&&&&&&&&&WW&&&WWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&&&WWP^  `7`  \xc` _ABP~  `````````````    ``      'tl}\z}      \z1jju\  zWWWWWWWWW&&WW&&&&&&&&&&&WWWWW&&&WWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&&&WXx   `a_  +bn+  \CA,` ``````` `+unac+`      ``|}+\,nqs     _z1jjsa"  \PWWWWWWWW&&WW&&&&&&WWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&&&&&&Wh_   \n} `2Iva|  `zC\   `     ```\1>`       `````+0Cu}   `"l7jjjj21   3WWWWWWWWWWWWWWWWWWWWWWWWW&&&&WWWWWWW    //
//    WWWW&&WWWWWWW&&&WWWWWWWWWW&&&&&&&&&&&&WA"    "Sl |Szj1]"   ~CC| `          `          ,l%$zc5` `"cvjjjj?jl3`  ,FWWWWWWWWWWWWWW&&&WWWW&&&&&&&&&WW&&W    //
//    WWWW&&WWWWWWWW&&WWWWWWWW&&&&&&&&&&&&&WP1     }Cz`+n7sj15}`  `}%x|`                ` _xFPzs7z~\+ccssjjjj??1I_,  iXWWWWWWWW&W&&W&&&&&WWW&&&WW&&&WW&&W    //
//    WWWWWW&&WWWWWWWWWWWWWWWW&&&&&&&&&&&&Wma`    `lnz-te?tjjszv'   ,bnz?,             `"1l"+Plslcvz1ssjj???jjjsx"?, `amWW&WWWWWWW&&&&&&&&&&&&&WWWW&WWWWW    //
//    WWWWWW&&&&&WWWWWWWWWWWW&&&&&&&&&&&&&XC\     \I]2+il}+sjssvz},  ,+"+22j-       ,"+}"`` +Acsssjsjjjj???jjsss3"3"  ,zxC0AOWXXW&&&&&&&&&&&&&&WWWW&WWWWW    //
//    WWWWWW&W&&WWWWWWWWWWW&&&&&&&&&&&&&&Wk|     `tncac}c}"ssjsssvz?^  ~+|,+cj}+"++++|```   +nsjssssssj????jssss2"n}   wXXXWWWWWW&&&&&&&&&&&&&&WWWW&WW&&W    //
//    WWWW&&WW&WWWWWWWWWWWW&&&&&&&&&&&&&&P+      ^xzsCx?v}>ss7sssssv2l+,`|"_```:,`````     `ccjj17sjs1j}??jjsjjsc+Cl   }XWWWWWWWWWWW&&&&&&&&&&&WWWWWWWWWW    //
//    &WWW&&WW&&WWW&&&WWWWW&&&&&&&&&&&&&Xl      `1zjzZ0cv}_sslsssjssrkn^^\'>"_-````        "esslcjsslc+}j??jsjss?rau^   xWWWWWWWW&&&WWWWW&&&&&WWWWWWWWW&W    //
//    &WWWWWWWWWWWW&&&WWWWW&&&&&&&&&&&&&C`      +zjjxPglc+_sszrsjssjlF>   `,:\^,          \2vcelsr7rzs"j??jjjjsstzv2?   `nWWWWWWW&&&WWWWWWW&&&&WWWWWWWW&&    //
//    &&&WWWWWWWWW&&&&WWWWW&&&&&&&&&&&&0,      ^ljszgWAll+~sj27sj?vub_                  `~ezrxnlslll5+"ssssjjjsr11s72\   `IXWWWWWWW&WW&&&&&&&&&WWWWWWWW&&    //
//    &&&WWWWWWWWW&&&WWWW&&&&&&&&&&&&&G|      ~cjscqXWAcl+_js3rllnbv,               ``^"+"^` `t8I5zzz>}sjssjjjjsjsssc?    `CWWWWWWW&WW&&&&&&&&&&&WWWWWW&W    //
//    WWWWW&&&WWWWWWWWWW&&&&&&&&&&&&&&z      "lrsvCm&WAzc+|s1ajeej`        `  `   ``-\\``````` `}u]5z>?sjsrjjjjjjjjjsc"    `CWWWWWWWWWWWWWW&&&&&&WWWWWWWW    //
//    WWWWW&&&WWWWWWWW&&&&&&&&&&&&&&&0\    :slsjcSOW&@Pz1">jcucz```````````````````````````````  ,23l>sj7zvsssssssssss7~    `IXWW&&WW&&WWWW&&&&&&WWW&&&WW    //
//    WWWWWWWWWWWWWWWW&&&&&&&&&&&&&&P+  ,|cnezz2AWmAS2lz1"+jzn]"    ```````````````````````````   tIc"ssexCxzc7jjjssjsjt\    `zmWWWWW&&WWWW&&&&&&&W&WWWWW    //
//    WW&&&WWWWWWWWWW&&&&&&&&&&&&&&m017lzzzzzczInl",  :c1"}jzCz,       ``````````````````````     \al+rcl`_lnT00qCnuuunCnelr+:`+AWWWW&&WWWW&&&&&&WWWWWWWW    //
//    &&&&&&&&WWWWW&&&&&&&&&&&&&&@Az>`````````````~>|``c7+?j3I|"}?j?t?153?^     `    `_?lzcr}+++"""zz+sl}   \""?7ti+"||||||_>+}r2CFXWWWWWWW&&&&WWWWWWWWWW    //
//    &&&&&&&&WWWW&&&&&&&&&&&&&&P?```````````````     `cs}j1n+         `|+j",      _llr>,````````  |e}sc+        ```````````````,+2kPGXWWWWWWWWWWWW&&&&WW    //
//    WW&&&&WWWWWW&&&&&&&&&&&&@g\````````````````     :2jijec`    ```        `````,|,```````````````11s7c`      ``````````````````,5&XmXW&WWWWWWWWW&&&&WW    //
//    WWW&&&WWWW&&&&&&&&&&&&[email protected]^`````````````````     +2jszc`   `````````````````````````````````````}z?c1` `     ```````,`````````,[email protected]&WWWWW&&&&&&&&&&W    //
//    WWWWWWWWWW&&&&&&&&&&&&&@v``````````````````    ,zcsls`    ```````````````````````````````````` `+zvcv\`      `````````````````tW&WWWWWWW&&&&WWW&W&W    //
//    WWW&&&WWWW&&&&&&&&&&&&&k` `````````````````    }3sl}`      `````````````````````````````````    `\7zll+,      ````````````````\AWW&WWWWWWWWWWWWW&&W    //
//    WWW&&&&&&&&&&&&&&&&&&&@a``````````````````    >alz"```````````````       ````````````````     `` ``\}czl+_^^',````````````````,[email protected]&WWWWWWWWW&&WWWWW    //
//    WWW&&&&&&&&&&&&&&&&&&&&7````````````````  `` |x21^````````````````                 ````````````````  `:|">~,`` ```````````````,[email protected]&&WWWWW    //
//    WW&&&&&&&&&&&&&&&&&&&W&t``````````````  ``` >Iz|```````````````````               ``````````````````````  `    ```````````````,[email protected]&&WW    //
//    &WW&&&W&&&&&&&&&&&&&&WM7```````````````,+_`+c>```````````````````,``          ``````````````````````````````'``````````````````e80XWWWWWWWWWWWW&&&&    //
//    &&&WWWW&&&&&&&&&&&&&&WWl```````````~"`}?\`_\````````````````````,'>+\`  `   ````````````````````````````````\+","``````````````n]"nXWWWWWWWWWWWW&&&    //
//    WWWWWWW&&&&&&&&&&&&&Wxtc`     ``````x]\ ````````````````````````,,:\i2t`` ````,``````````````   ``````````````:cq-````````````^h1s+xXWWWWWWWWWWWWWW    //
//    WWWWWWW&&&&&&&&&&&&WC^?1       ```,lI: ````````````      ```````,,,:'\cC"`+_,-,,```````````     ````````````````"a>```````````"%sst|0WWWWWWWWWWWWWW    //
//    WWWWW&&&&&&&&&&&&&WS^is2        `+n}``````````````````    ```````,,,:''+Fg3\\',,,``````````   ```````````````````:2+```````  `jSsss^iPWWWWWWWWWWWWW    //
//    WWWWW&&&&&&&&&&&&W8~+ssn`      ,aa:```````````````````````````````,,,-'\iG+^\'-,,``````````````````````````````````r+``      `]5sss|,CXWWWWWWWWWWWW    //
//    WWWWW&&&&&&&&&&&Wq_+jss8"    `>$?```````````````````````````````````,,-'^0j^\':,,,``````````````````````````````````t_       `I1sss"`sOWWWWWWWWWWWW    //
//    WWWWW&&&&&&&&&&WF>+vjsjIc`   +8|`````````````````````````````````````,,-\Cz\\'-,,,````````````````````````````````` `c-      'xssssr,>AWWWWWWWWWWWW    //
//    WWWWW&&&&&&&&&&Pt_3ssjsc2`  +S\````````````,,````````````````````````,,,'a5\'-,,,``````````````````````````````````  "v`     tljsss2',0WWWWWWWWWWWW    //
//    &WWWW&&&&&&&&&XI`?esssssI' |8\`````````````````````````````````````````,-zz'-,,`````````````````````````````````````  v'    `asjss1]-`8WWWWWWWWWWWW    //
//                                                                                                                                                           //
//                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NOX is ERC1155Creator {
    constructor() ERC1155Creator("Noxverse", "NOX") {}
}