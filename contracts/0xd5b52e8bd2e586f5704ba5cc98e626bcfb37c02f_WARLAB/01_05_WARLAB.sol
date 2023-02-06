// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WarGames Labs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                               //
//                                                                                                                               //
//    [email protected]@O#@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected][email protected]@[email protected]@[email protected]@[email protected]@[email protected]#[email protected]@[email protected]#[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]#[email protected]#[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    RBE0QK$QXQQIQQ3QQIQQzQQyQOqQddQyBQVQQzQQXQ8qQQIQ0XQ0dQeEB3BB3BB3BBMBBZBBd#Q$#8$#O##O##E##$##E##[email protected]@XdRzQKQH    //
//    RB0EBK$BIBBIQBeQQXQQXBBwQRMBOOQwBQyQQzQQzQQ3QBIB$IB0OBIEB3#B3BB3BBqBBMBBdBQ0#g$#O##O##E##0##E##dewIMMRd#[email protected]@O    //
//    $      .H##c##y      w#3#Q0#g8#K##e##H##q##O##,            :M##d##O##R##0##Q#BQ#$##[email protected]@[email protected]@[email protected]#[email protected]#OeyIeweI#[email protected]    //
//    O?      xQ  IQ       0,         ^8*         `$      iT      ^Q.         :#r        `      d#^          Zw          \[email protected]    //
//    RB       ^   H      -.    'I     e-     ?    \      ^ :-  ';KV     3     Q     vr   \T     R     )      r     3     VQe    //
//    E#Z                              K-    .IRVrwQ      =,      ^Q^          8     $q   RB     O           YX`       ,~#[email protected]    //
//    [email protected]:       x       \      )Q     R!    :[email protected]@[email protected]@      T)      \_    `Q     #     BR   Q#     g     Ze` ``ex     ?     IQK    //
//    RB00      Oe`     Tg-            O_    .eQQMQu              **           Q     $Z   gQ     8           ;T           [email protected]    //
//    EB0$Q}eqi$BKQZYqqVBBi_`    `~yq}BBwqHxHQIBQx,    ;r_`     `IM#QcZZuZZcZ0d#gXZK3#O##O##3ddXQ#08dcx\xxv}XQzITH\v3vcwYQ38e    //
//    [email protected]#@E#@[email protected]@[email protected]@[email protected]@[email protected]@Rg^'`  `-*[email protected]@[email protected]@[email protected]@O#^   `_x?,-...''.*#[email protected]@[email protected]@[email protected]@[email protected]@[email protected]#[email protected]#[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    EB00B3$BKBBKQQqQQ3QQeQB~-`   .!*QQXQQeQQ?`   `:\!-.``'.-:iBBqBBqBBZBBZ##O#Q$#8$#O##R##0##$##0##dewKezeIQzXeQXXBXdOzQ38I    //
//    EB$$BHgB3BB3BBMBBHBB3BB;^,`   .~3BIBB3$^    `:*-`',!^vcZQM##M##M##d#Bd##R#Q$#Qg#E##E##$##$##0##dKwIezeXBwXH#[email protected]@[email protected]    //
//    EB$$BqgB3BB3BBqBB3BB3BB;~;!.` `_^ReQBw=`  `._~-,^vuVqQH$BM##M##M##Z#Bd##R#Q$#Qg#R##R##$##$##0##[email protected]    //
//    [email protected]#@0#@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@dZ?:_...'''......-,,:!^)}[email protected]#[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]#[email protected]##@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@gqwIeweIQzIKQze#[email protected]@E    //
//    0B$$Bq8BHBBHBBMBQqBBHBBz).          `````'.^iydQ8HBgEBq$BZ#BMBBZ##d##O##R#Q$#Q8#E##0##$##$##$##[email protected]#dZBXdOzQKQe    //
//    0#$$BM8BqBBqBBMBBHBBqBBx,`            ``--_?IQMB8qB$EBH$BZ#BZ##Z#Bd##O##R#Q$#Qg#E##E##$##$##$##[email protected]@E    //
//    [email protected]##@$#@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@c^:.'`        ``.!^^\[email protected][email protected]#[email protected]#[email protected]#@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]##@##@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@IZOzQKQI    //
//    0#$$#Z8BqBBMBBdBBMBBqBBV**^,.        ``-~xx^*dZB8M#g0#M$#d##d##d##d##O##E#Bg#Q8#0##0##$##$##$##[email protected][email protected]@E    //
//    $#gg#dQ#M##Z##d#BZ##M#Q^^:^;-`       `._^x:,!r3#QZ#8$#Zg#d##d##d##d8EXZqIR0g#QQ#0##$##g##g##g##[email protected]@MdOwQKQK    //
//    $#$g#dQ#Z##Z##d#BZ##Z#I,.'-;,.`      `.,*\_-,!;dQZ#8$#dg#O#Qee}^!_..''''`'.-!?w$E##$##$##g##$##[email protected]@[email protected]    //
//    [email protected]##@g#@[email protected]@[email protected]@[email protected]@[email protected]@[email protected],---,-'.`    `.,,=*!-_!~?~.-~vIu}?:'``          ```````'-:*[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    g#88#OQ#d##d##O##d##d0*:,::.``'--..'-,,-_!*!,=^\r`  `.--'               ```  ```_.'_\q$##8##g##deXdOwIXQHOR#[email protected]@M    //
//    $#88#OQ#d##d##O##d##d$\;=^=.'``.:~^^~_'.-:*\^rxx:    ``.'                 ``` `.''`',:=IBQ##g##[email protected]@dQRzQKQd    //
//    [email protected]##@8#@[email protected]@[email protected]@[email protected]@[email protected]@[email protected])v*!:,-..,=!,-_,:;vuxYx=.    ```                  ````...``.__-,*[email protected]@[email protected]@[email protected]@[email protected]    //
//    g#8Q#RQ#O##d##R##O##O##Kyuux)*^^^^^^;^^*?ucv)='``    ``               `` ``'..,,'`'....-!^e#8##dIyMOyeX#[email protected]    //
//    8#QQ#EB#R##R##E##R##R##R8ixxiY}}YYvviTcci^-```      `'`              `````.-,::.  `'`..-:;^38##dMHIIwZd#[email protected][email protected]#I    //
//    Q#QQ#EB#R##R##E##R##R##Rz_---.-:*vxx\^:'`     ```  `._`         ````''..-.-_-.    ``'-__,:=^e##$qyIHM3XQKOdQzz#dQgzQeBR    //
//    #@##@Q#@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@0;.````````'.`        `'.`` `-_`        `''``'`..--.'`     `..--,,,!^[email protected]@KXIBZd#[email protected]#e    //
//    Q#QQ#$B#E##E##0##E##0##T~,..'```````     `'``'.. `''-_`    `''...'`    `````''````.--.-,:,!~*}#dKqIXzR3QwqR#zzQdQQzQe#R    //
//    Q#QQ#$B#0##0##$##E##0##u^!,--..'''```  `'`  ``.'``-,:_`   .-_-'`            ``'..`'.,-.-:!!!*x8OdVXM3IzBZ3IQMd#[email protected]    //
//    #@##@Q#@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@T*~!:,,,_-.'''`'-`   `.-,.-!!:-`'_,::,`         ```'....-.`',~,`-!^==?xZgzVqqyId#[email protected]#E    //
//    Q#QQ#$B#$##$##$##$##$##XYxr^~!,_-.-----````.,!!-``.,:_`.!;^:.'``     `.-`---.'``.-,;^,.,=*~*i\[email protected]@EQX    //
//    RHHRHH0HH033$3Z03Z$3dE3dK\??r=:::::!::,,,,!~^:'.,!~^^,..:^=:__-.``  '-.'',-...-,!~^^_--:~r!^\\[email protected]@[email protected]    //
//    xw)xw?\wxvw}\VYxyTic}}uTuTxr)\*^^^^;~==~~;;^!-_!^!~r!.,!*^:!==!:,___::...,..-_!^=::-.,=;*?^)[email protected]@EQI    //
//    VxXIiyKVTewuXXVyezwewIzXKzHT}Yixv?r*^^^***^=:!*r~!^~'.!;=:!~^^r**^^^^!-,!,``'_;-.-!,~^*rxxvv?iY```-*XHzQZII#[email protected]    //
//    iwc}TwTuwcVcwTzVccwyTKcVyIweIiixv\\??)rrr))r)\v)?\*,,==,,~~=*****^=!:=~=,.-,!*^,:~^^*r?xY?^*\x)   `.!VM#[email protected]@R8X    //
//    XyXcXyeyzyeIyzKXyX3zyIMwy3HwzMzVuuTT}Yixxxxxxv\vr^^;~:,,!^^~~^;^^;!!!~==~^**^^!:~;^;*rvi;!;^*Y_   `.!}[email protected]    //
//    dOdddRddORdOEOZ0ROZ$0OZg$OMQgOZReuTTuuuuTTT}TTYv**;!,_,:~r*~!~^^^^^;==.''.---_.-,!*r\?*;!^*^ix`  `-:*V8Qdeq#Vw#[email protected]    //
//    3yVXHwyzHIVX3Hcz3Myy3MXc3ZecIZqTXddcwyXwwyyyVi);!:,,,,!~**^!::::!=!::_---,=;!!!;*?v)r!!)*x)ic-  ':~*}[email protected]    //
//    EEOZd8ZOqgEdZRQddZQ0dq$QdM0Q$ddQQOH8Q0wrr=~\Y*!,__-_,:;*r*^,,,,,,,:!~^*^***!!^??r!!*^~v}YiTc!``.:)[email protected]$I    //
//    ddQdOM$8qOOQ$dZ$QRZdQQdd0QgZZQQEqRQQZMc-...-!^,-..--,!=;;=_`'-_::!!!~!!;~!,'-^::;^xYviyuY}c!''[email protected]    //
//    HqdggHMdQ$HdO8g3ZEQ$HZ$8$KdQQ$KR88$Kz?.     .,``   `.-_,.     ``'-!**^**r?vxxv)vxTVu}v?*xc*!~*[email protected]$3    //
//    QQdMRQQdMOQQEMOQQ$ZdQQQHdQQQqdQQ0}``       ``````   ``.`         `'.-:=^)vxY}TTcu?;,_!^[email protected]    //
//    Md8Q$MZgQQMq$QQRMRQQ8qdQQQdZ8QQq.       ```     `'``.'-          `-_-----_,::!!!_-_:;)yIKdEg#QQ0KQQQ8egQQQqdQQQd3QQQ$$H    //
//    QQMH0QQ$qZQQQdH$QQQqZQQQR3gQQQI:` ``   -.```   `._-._,_'.'.``  `.,:!=!!!:::::,,,::=rI8O#QQQKdQQQ$zQQQQqMQQQ0e0QQQM3QQQ0    //
//    qdQQQZH0QQQMqgQQ83MQQQgKRQQQ0eQB$RXHMKIx;:,,,:!;^^^r?i\??))r^^**)\x}TicVzXKVHddR0HB#QQM3QQQQHOQQQ8X$QQQ$IQQQQd3QQQQHZQQ    //
//    QQ8Hd0QQ8HZ0QQQ3qgQQQHqQQQQ3MQQQQMZQQQQqOg$$$K$$$g8K0QQQQIgQQQ8wQQQQQwQQQQQwQQQQQygQQQQXgQQQQI$QQQQI$QQQgK0QQQ$H0QQQ0H0    //
//    OZZQQQgHdQQQQMZQQQQdHQQQQE3gQQQQIRQQQQHdQQQQdZQQQQgIQQQQQwQQQQQzQQQQQwQQQQQKKQQQQEzQQQQQwQQQQQzQQQQQKRQQQQMZQQQQdHQQQQd    //
//    0QQQRZdQQQQdqQQQQ0M0QQQQMdQQQQE3QQQQQeRQQQQO3QQQQQzQQQQQddQQQQQzQQQQQyQQQQQQzQQQQQzQQQQQRqQQQQQwQQQQQqOQQQQE38QQQ83OQQQ    //
//                                                                                                                               //
//                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WARLAB is ERC1155Creator {
    constructor() ERC1155Creator("WarGames Labs", "WARLAB") {}
}