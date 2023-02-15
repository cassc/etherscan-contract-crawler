// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Touch Grass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                             ''                                                                                                      //
//                                                                                         .!////t/"                                                                                                   //
//                                                                                        ~|".....-t/.                                                                                                 //
//                                                                                       ]^         "|I                                                                                                //
//                                                                                     '              I_                                                                                               //
//                              I                               ^                       >              "_            .                                                        "+++++~~`                //
//                               )                              .:                      !I              .!          !                                                     .>}t|[_++++[|/?i             //
//                               ^1   .;;;^                     .?I_||?;  ";.            j^              .^         ~                                                   I([-.           ^?}<'          //
//                                )+ i  l}1/["               ',f//|1        )i.          `x.              +        ~            .                                     ;1I                   [I         //
//                                 r"       |/t'           '(/f//- t         +tI          tx               ~       c            ..                                  '/                        ).       //
//             ||///tt>            {x        .?t1        .|/t/t!   _?         .ft          x[              !      ;l             }                           +     _`                          `       //
//           ^""",}jffjj(l         .fj         ^t(      :ttt/}'     f"         `jj}        )x"        "     ?     Y               f              `l>I.       ,    {'                                   //
//                   Iljjj/<        [r?          >(    ]/t|fI       ;n||//,      {f)       .nx         {    )    .J               >(       (|nJJCCLLLQQQQrri}    !                                     //
//                      l-jj{.      .fn`          i(  ?tf/).      .^ t{ !-UU{     +jj^      (n)        /,   "^   |1       >        x?  .}uYYUJJJCU[??<'     t   i                                      //
//                        `[rrl      1jj   `       +[_tf/[       .}  "j"   1CUl    +rr:     'nn,  l    ~t    ) l^L{[<>;  -         Ix>1zXYYYU11`           _^  :'     l+___~>-]:                       //
//                          !jxi     'tni  [        /ff|}        n    /j    <JJ>    <rr"  '  jnn   ,   't!   f  `Q  `[tfi~         `nnzXXj|.  ^            C   [.i>uYYf|].                             //
//                            /x!     tfx   i      .jj/(        (!    ^jl    ^JL<    ixx"~   ,un~  f    //   -^ /Q     /vj,       ;ccxuj       -          "v ,[XYYur^                                  //
//                             fx:    ;jn{  x      {ttf        lv      fr     .JL,    >xr     uuu   +   //i  ^} 0c     c:fjj.    {ccunn!       Il.        u}YYYz/  <                      .''''        //
//                        .     fx.    rjx1 '{     tjft        c:      "j<     "CC+   r_x1    ]vu(  Y { -/t   j O]    )c  jjf.  fcv^ lnn   ;)czYYXccx.   vCYYX'   {.                   "vu:''''        //
//             "           .}'   nj    [rnvu.Y    ?f|?{       rc        rrI     _QX,|f  1x,   .uuu. ut  ,//:  jlO,   `c:   {jj"/vI    unt_X_I,  _| 'I:cjYJC+^j   ~;                 Ixv:.              //
//              .'"     .    >/  `x]   .rrxXUc[   jff ;"     :c!   '    )nI      x0(/ji  jr    xvufu!Y   t/|  fvO    nc   ` ?rr|`     ?vJ?  f   ./+  (UUYJY :l  "n                {u{:                 //
//                '!:+(-?t{>  ;X! Ix.   rjufXUX   ftI .}     uc!+_[_i  [rxf ~1{_1tQ0  )) 'x_   !vuuI n+  t/t. |ZZ   lc<   "  jrr.     |Xnr [>"   |/^nJJ].0j?t   v^              iv?^}                  //
//                 i++    ^-]  `Y- 1|   -xxu`UYn ^ft   j    ;c|,."!<-txu^]r-;l'  [uQ]  1v'in  "rvvu| lY  ///_ [mm   cc   )  +:|r/   '1 fuux  u   !/rJ|' '0;.n  |j          ^   }1. n                   //
//                l` .);    ;{  .U{ x.  .xjn)`UUY?tI   j    cc.  X  :jv1r-r]>   [n'XO"  /J"f-icvvvuv  Y` )/|/ _ww  ;cf  >^ I,  jr> :x  :uuu  t,  -//<   ]O ++!:c`         +  "vI  j;                   //
//             `""l!l:"t>    .<  'C|+1   xxcv ,YJrf    j   `zc  1I  ncc  1rx.  _n!  Qu   nC,nccn-vuu- zf,{/|t'+mm  vc" 'z `j"  `xx^z   "unu~ 'z )J/t{   JO j' Yu   '    'x  "x   }r                    //
//          .}((((|||||||/+'  >   ;C(x   |xnni YJjf    f"  tz? 'Q  xcc.x. !xr'In)   cL{   JCnvv .uccc'uU l//t]}wL  zz  z` v. n' -xp   'cvvvv  YjU'-t/   ZZ f ~c!  ..   'u^ '(   ;c                     //
//        i)|((((|(((((|)|//|` f   |Lc:  ixxuc uYtUY   /!  zc  C? /zz( 'z rxrxnn     0lu  cLCn.  cccc;'Y"^ttttvwJ {zj lJ |/   r! Zx   cc^unu> tc. `/t-  mZtf cc ' f   ,u} .?    c/                     //
//       `'  ;  .  `":1|||||/t1l^   QCt  .rxzz ~YtLL|  )? ;zz _L _zzz   <n`)jnn|     QUxYrXULn   vcvv| Y|.tt|tZqX zzI J!^c^    }cnx? uz? cvcv/;Y   //t fmQ1{<c{  ?.  ivu .{    uz.          '^'        //
//             l!)1!    ,I(////t|   ,0x   xxvu_.Y/QQLl 1) jzt Qc"XXz]   -nX"xu(x[   ,Xc?ULYXJc_:/xcccz zY ft|tUpc.zz 1C uu      qz{n}zz  jvuu> Y<  t//n/mct>vc. 'j  >cv^ x    -z|       l]|t{I;;"!     //
//                ^~x|].   +t/ttt?   xrx  xxxuv J|-QQQ )t zz!)L"zXXz    u^nzxu ~x+ ,Y'w{xUCf`LXx!Icczz`1Y ft/tjpz-zY Lriz+     XU{JnzX<  ivucj xz 't//1vwrtIcz  c' !cc{ v.   'XX'     ~//>;            //
//                   I}zjuJCCXx|//1  .vL: |xrcz Cf"L00j(t.zz.0Z|XXX}   {u 'vn-  ]xlY~ UYjXYY.JnX .czzc};X!fttffbXvzx|L^zz'    ^q" fuuX    vccz <Y_zr/t/0wvtfc{ ~v ,zzc <+    xXr    ,|)<               //
//                   >UJJJJCCCCCxt/|  tcO _xxzv:ux?!OO0/t<zU{OUXXXX   'v? rzuj   /xv `CYnuI[ztjZI zzccz YrftfftbUzY_QQIXv     Cd  <znt   +cccvi'YXz]tt/wqX/zc` C,.Xzz~ w    IXX^   it~                 //
//                  tUJJJCXJCCJL0jt/|  rm>;nxzu|[xx ZOOLtfXU00JYXYx   tc Izzzu?,{///tt/zcf.fY'(QZ XzczX Y0ffftf0LzJ)QncX1    'pt  YXxQ: "YzcncnXYY'^t//Ypzfzz tL vXzc }|    YXz   [)                   //
//     .!((|/t;.   zUJJL"  ~XXvt vx/t[ fmw'nncnX,nu /ZOZtzYLZZYYYY^  .zzcczv/|)(|//||/tt/tff'v_vwlzzcXX^XOftf/tvqXJ00IXX:   'uXzcccczXC.UU}vvzzXYY .tttjpcuzX.L{[XXzi q    +XX(cnx[_ucu}`.             //
//    ..    '.|t|:1UJr' vl  'YYY}`fO[/,j0w;nnnzz nu,.mZZJXJ0ZdUYYY  Ivzczn||(1|(||))(((/tt/t <:rmZnczXz]n0jfj|fjZUCOOfYY   |ccczcxXX>Jrjx|IvzzcX/X. tttfbczz{uL'YXXX iw   ^zcux`l(   'rccv/            //
//             '"tJY,   'c)  .XJU.t i~/(YwQnnrXX.fn| wmmmYCOOmUUY[ xXczx|(((|||(uc"cxnYC?(tt/?{jwwfcXXzu1Ojfj|jjmJOO0YYX  nzzzcv/UQ0.lOYrr/zzcvx:Yi ttffkzzY:QLzYXX_ Zn (xuvvx  f      ,zcXu.          //
//               [tt[    ,c1  lXC0ti n<fuwqnnrYc>tnu JmmZJOwOCUUX+zzcv/(((|I;jCCC>IJvcuLXzvnv|jUqqLcXXzY<0jfj/jjwCZZLYYx vzzzzj QOOt l0ZYrxzzncz Yt tfftqJXJfQUYYYY  p]nvcvjXI ).       'czXv          //
//               n  <)    (z_ .tUOf( `QjUqpunrXnfjuu,-wwOJZwZUJUYzzcr((/vY} tjOCC:YJYuu0XzczzzrxddQcYXXY"0jjj/jjw0ZZCYY]rzzzzv -ZZO^ jLZZuxzznXX Yu<(||nJ0YC00JYYYj ?CzuccuUU ._         .zzX_         //
//               .   lt.   zz" tfOxt  ULfbduunYuUxuvt.qwQLmmqJJYXzct/r~OJJ`1|fdLLcCJJncOX~XzzXXzzkwcYXYY.0rjrtrjOmmZJUY1zzzzXU OZZL `ULZmZxXcuxx1{xiunffuZJL0OUUYY"`vcvccnJUc }           >XXu         //
//                    `(   {Xz ffcct/ YzcXknuuUcCxcvc pq0OmmkJJXXvjvX0(LCCir,jkLLLCJJzrZv XYXzXXXQdCYzYX,0rjrtrrLqmmJUJYXzXXub'ZZQn zULOmmXcf11j{YC jjfjjZJOOOUUUY^Xzuzc[JJL< z            czc         //
//                     `~   XX>|fnYtX^xYcvbzuuUXJ(uuv,mqQmqmbCUXXzXXUZZLLCY/JrhQLLLCJUxZn'XXQXXXXzpZJzUX~OxjxtrrJdwmJJYXXXXXnXfZOCi:QU0xw0|((tQLv/U^jrjjjwLOZLUUU{XzvXvx{QZZ <>            ?X}         //
//                      i   zYU{fnntxO(Uuur0nuYUU?ruccCpQwpwpCXXXXzXZLQQLCz!QrhZQQQCCvumu{XXOXXXXXtmmzUX1OxrxtxrYbwmJLYXXXXzb_mZLC 0OJOixf|/C0JXU?Y<jrjrjwOZZJJUUXvXcXz.ZZZZ j              X          //
//                       ]  _YU(fnntfZ1Uucv00uYUU<xczzndQwpwZJYYXYXUmU0QQJcL0xhwQQQCCfUZuuXXQLXzYXzOmJYXxOxrxtxxXbwZCUXYXXYuh'mOLLi000QttjtO0JYUUlU)rxjrjwwmmJJJUzXnzz} ZZZx j              `          //
//                       ]  .UYnjnuttm0UuzurOcYUXlCzzzxkmqpq0YYUYYUZw0OO0UXOOua(000LCjLZuntXCOXXXzXjmZUYUQxrxtxxzkqO0YYYUYYxh~mQLL0ZLYxfxfbZUJYJJ^JuxnxxxmpmmCJCXXczcX.{ZZQ!i)                         //
//                       .?  YUujuuttq0YuLvnOOXUcimXvcXhpppp0UUUUUUwwZZOOUZZZzaCO0OLXnOmuutXJOXXXXXvmZCU0JxrxfxxXkp0QUUYUUYLazO00zmmcnnnrhkOJCzCJ^CUnuxnxZdwmCCYcXuXz) 0m0C |i                         //
//                        j  UUnjuuttw0XnmzcJOJJc<wccYUadbddLJJJJUCqwmmmZUqmZJokOOOQxzwquufzUOCXXYXz0mOUZvxxxrnnYhpZCUJUUJUbowOOOZwUvnvxpkkOLLXLC!CLuvnvu0bqmLQYXzXcX^ mZLL f'                         //
//                        {! UUxjuuttm0zuwccjOZCz-wuUJUddkdbJCCJCJmpmwwwwLpw0QmkZZZ0rYqqvvjnYOOXXXzXxmmJZnxnnnnuJhdmUJJJJJJaamZZOmCcvcvwdhkZLQYQC]LLccvcc0kpZ0CXUuYzc'"mQLJ`t                          //
//                        :/ zJrjvuttmQcuwcuzZmLX[wXJUUQbhbkCCLCCCddwwwwwmdpCqLbmmmOxUpdcvjjUZOXYXXXnmwLZnnunuuvQhbmJJJCJCYakmmmZ0zcXXOdqhhmQ0J0Q|QLzzczzQhdZZJYUXUYx`/ZLLx-t                          //
//                         j zJrjcxttwQvvqXvzQmOY)wOCYCCkhkdLCLCCQddwwqqqdbpUhakwmmQnJbdccrrUZOYYXUYXwmZQnnvrvucmakmCCCLCCzohmmmZXXYXXdppaaw0OCO0x0LXXXXX0adZOJJUJUUQ"Z0QL]tt                          //
//                         flUJrrcxfjpQccpCYXcmwJCqpLJLCdhkwLLLLLObdqqqqqkkbY*odwwwLc0kdzzxxYmOUYYJYYOwwzuucxcvcdakZLLLQLLYahwwmJUXYXbdqbaowOZQZZcOCYUYYYOakwQJCzJYCbIq0QQlt)                          //
//                         t}CJrncrjjb0ccpQJUzmpJLwqCQLLZahOQQQQQpbbppqpphhbU*opqwwQUqkdXznnzmOCUUJYUcdqccccvzczkoh0LQLQQL0opwqQUXJCkkdqaoowZZOmZYOCJJJUJmokqQCLUCJYa<ZOO0"f]                          //
//                         ?fLXxvzrrjkQzXbQCUCmpQQZpJQL0OaaQ0QQ0QkkbqpppphakJ#opqqqLLkhpXcnnXmOLJJJJJckOzczzzzzXooaLLQQQ0QdomqwJJCCChkddo**qmmZmmJZCCCCJJp*hp0QLLLCca1ZZOO>j_                          //
//                         lfCvnXzrrrpUXYkQCUC0dmQ0dQ0L00ao0O00OOhhbqpddphodL#oppppCLhhmYvuuJwOQJCJCCJkLXzXzXXXY**oQQQQQ00aomp0LJCChakdb*##wmwZwwLZCLLLCCk#aq00C0LQLaZmZZO{r>                          //
//                         ^fcuuXvxxuwXXLhLCUJUdp00dwOOO0po0OOOZOaakpddddkoZqModddpJOaaQUcvvQmO0CLCLCLdLYYUzYYYU***Q0000OOooppCJQQQ*abdh###wwwwwwQZQQQQQL*#ow0OJOQQdodwmmZrr!                          //
//                         .--?]}?--1/}}(r11}{}ff((ff(|(||x|||((|rrjtfffffx)rnjffff1trr1{[]](||(111())/){{{}{{{1xxx(((((((xxf/)1))/xrffxxxxt/t/tt|((((()(nnr/((1()(rrt///|?-,                          //
//                                                                                                                                                                                                     //
//                             IiiiiiiiiiiI     i>i>"      >I       .>"     .i>ii:     il       ii           ">iii`     iiiiiii;         i:        'iiiil      `iiii;                                  //
//                             O&&&&@@&&&&Q   )@@&&%$8^    $d       I$x   [email protected]@&&%@@^   $a       [email protected]         `&$%&&[email protected]   B$&&&&[email protected]      [email protected]@       [email protected]&&[email protected]@;   [email protected]%&&8$$^                                //
//                                  $$       8$x^  '^@BI   $d       I$x   [email protected](^  '^@B'  $a       [email protected]        ,@@^.  `_$8   B$    .,@%      @[email protected]     x$x'   ^d,  [email protected]]'  .^W`                                //
//                                  $$      [email protected]>      '@@   $d       I$x  #$l      'i   $a       [email protected]        @$'      !i   B$      q$     #@.p$     *$          @@                                        //
//                                  $$      $#        <$v  $d       I$x  @*            $o,,,,,,,[email protected]       )@{            B$      &$    [email protected] '@a    ~$&01.      [email protected]#0-                                     //
//                                  $$     '@L         @p  @b       [email protected] '@L            [email protected][email protected]@@       [email protected]^     UUUY+  [email protected]    @W   j$+    it*@$$kz    [email protected]$$qz                                 //
//                                  $$      @&        {$j  $8       /$_  @8            $a       [email protected]       _$r     [email protected]  B$kkk*@&>    [email protected]@$         [email protected]       [email protected]@                                //
//                                  $$      0$1      :$B   *@;      %@   [email protected]|      'u<  $a       [email protected]        M$i      l$/  B$    b$_   ,$*[email protected]  :       U$+ l       p$^                               //
//                                  $$       [email protected]^[email protected]&.    %@>I."[email protected]@j    [email protected]^ !>@Bl  $a       [email protected]         *$)i''i|@$/  B$     #$l  8$       [email protected]^ $$ii. `[email protected]@  [email protected]  ^>@@                                //
//                                  $$        ,&@@@$8Z       &[email protected]$$B&.      '&@@[email protected]    $h       [email protected]          r&[email protected]& $/  %$      %$.-$J        $8  &&@$$$B&    &[email protected]@@$B&                                 //
//                                  ^^          `^^^          .^^^`          `^^^      ^'       ^^            ^^^`  ^.  ^^      '^.'^         ^^    ^^^^`       ^^^^`                                  //
//                                                                                                                                                                                                     //
//                                                             jr             f00000Q   C}   z00000X.0   .0   )00[   0000"  0    0+ C0000[                                                             //
//                                                             Q0             ~{{@{{}   Wr   ?{{@{{?'$   .$  qZ|thZ  ${{t$! @#   $1 WQ{{{l                                                             //
//                                                             QkM0%+`@'  @'     $      Wr      $   '$   .$ f8    @- $   &X @CW. $1 Wr                                                                 //
//                                                             QM  [email protected] mm vd      $      Wr      $   '$wqww$ d0    aL $[[}B, @ O8'@1 Wommm                                                              //
//                                                             QO  `@  $'@.      $      %(      $   '$   .$ [email protected]   .$] [email protected]  $  wB$1 Wr                                                                 //
//                                                             [email protected]^^Bb  CBo       $   [^,$`      $   '$   .$  &%^^@o  $  [email protected]' $   [email protected] Wn^^^`                                                             //
//                                                             ~>}z:   [email protected]'       }   ;Lc^       }   .}   .}   ^|(^   }   +? }    ]; ][[[[+                                                             //
//                                                                    +h*                                                                                                                              //
//                                                                    I[.                                                                                                                              //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract grass is ERC721Creator {
    constructor() ERC721Creator("Touch Grass", "grass") {}
}