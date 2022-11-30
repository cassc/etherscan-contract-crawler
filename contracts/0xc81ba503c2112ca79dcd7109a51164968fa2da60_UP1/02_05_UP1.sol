// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Uncanny Portraits, Phase 1: The Departed
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//    [email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected][email protected]$$$$$$$$$$$$$$$$$$$$$[email protected]$$$$$$$$$$$$$$    //
//    $$$z                               `<_:. [email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$} 'i-,                            ^$$$    //
//    $$$z                         :[~`  [email protected][email protected][email protected][email protected]$f. '+?^                      ^$$$    //
//    $$$z                        >[email protected]%v^ &[email protected][email protected]$$$$$$$$$%?`u%@%                      ^$$$    //
//    $$$z                        %[email protected][email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$r                     ^$$$    //
//    $$$z                       '[email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*                     ^$$$    //
//    $$$z                       [email protected][email protected][email protected]                     ^$$$    //
//    $$$z                       [email protected][email protected][email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$                     ^[email protected]$    //
//    $$$c                        [email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$t                     ^$$$    //
//    $$$c                         ,[email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$b                       ^$$$    //
//    $$$c                           o$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$b                        ^$$$    //
//    $$$z                       ..  '[email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$W^  ..                    ^$$$    //
//    $$$c                     `|*ofuM$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ofYMmI                   ^$$$    //
//    $$$c                    '&[email protected][email protected][email protected][email protected][email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$B&_                  ^$$$    //
//    $$$c                    ([email protected][email protected]$k                  ^[email protected]    //
//    $$$c                    @[email protected][email protected][email protected]$$$$$$$$$$$$$$$$/                 ^$$$    //
//    $$$v                    :[email protected]$$$$$$$$$$$$[email protected]$$$$$$$$$$$$$B}                  '$$$    //
//    $$$c                     :[email protected][email protected][email protected]$$$$$$$$Z                   `$$$    //
//    $$$c                    ^[email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$]:                  ^$$$    //
//    $$$c                   "[email protected]$$$$$$$$$$$$$$$[email protected]di                 ^$$$    //
//    $$$c                  :z%[email protected][email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$Zi                `$$$    //
//    $$$v                 [email protected][email protected][email protected][email protected][email protected]$$$$bl               `[email protected]    //
//    $$$c                 IJ%[email protected][email protected][email protected]               ^$$$    //
//    $$$z                   ;J$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$&>.                ^$$$    //
//    $$$z                     v$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$8,                  ^@$$    //
//    $$$z                      @$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$[email protected]$$$$l                   ^$$$    //
//    [email protected]$v                   "+0$$$$$$$$$$$$$$$$$$$$$$$[email protected]$$$$$$$$$$$$%{;                 '$$$    //
//    $$$v                  .1W$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$[email protected]c`                `$$$    //
//    $$$z                   [email protected]@@[email protected][email protected]$$$$$$$$$}'                 "$$$    //
//    $$$c                      #$$$$$$$$$$$$$$$$$$$$$$$$$$%.       .h$$$$$$$$$$$$$$$$$$$$$$$$8v         [email protected]$$$$$$$$$$%,                   `$$$    //
//    $$$z                        d$$$$$$$$$$$$$$$$$$$$$$$v            z8$$$$$$$$$$$$$$$$$$k~             [email protected]$$$$$$$$$$$$$)                     "$$$    //
//    $$$z                         `Q$$$$$$$$$$$$$$$$$$$$k               ;C$$$$$$$$$$$$$#~                !$$$$$$$$$$$$$$$$$$$$u                       "$$$    //
//    $$$X                           [email protected]                  q$$$$$$$$$$i                   M$$$$$$$$$$$$$$$$$Y'                        "$$$    //
//    $$$c                              b$$$$$$$$$$$$$$$a                    W$$$$$$$W.                    #$$$$$$$$$$$$$$$a'                          `$$$    //
//    $$$Z                               {$$$$$$$$$$$$$$$'                   [email protected]$$$$$W'                   >@$$$$$$$$$$$$$$|                            >$$$    //
//    $$$O                           I*l|$$$$$$$$$$$$$$$$$'                  [email protected]$$$$$$]                  X$$$$$$$$$$$$$$$$$Z+#I                        i$$$    //
//    $$$0                            `8$$$$$$$$$$$$$$$$$$L                 1$$$$$$$$$$<               `#$$$$$$$$$$$$$$$$$$$8,                         i$$$    //
//    $$$0                             ;%[email protected]             [email protected]$$$*:           |#[email protected]$$$$$$$$$$$$$$$$$$$+                          !$$$    //
//    $$$Q                             `%$$$$$$$$$$$$$$$$$$$$$W'        >M$$$$$$$$$$$$$$$$$8o:   'mB$$$$$$$$$$$$$$$$$$$$$$$$                           l$$$    //
//    $$$L                               [email protected][email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$8l                           l$$$    //
//    $$$C                               }[email protected][email protected][email protected][email protected]$$$$$$$$$$$$$$$$$$$$$$ -z,%[email protected][email protected]$$$$$$$$Mu                            I$$$    //
//    [email protected]                                  [email protected]$$$$$$$$$$$$$$$$$U    #$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$B(                               ;$$$    //
//    $$$J                                       ,n$$$$$$$$$$$$$$$$$$$$$$$$$b     [email protected]$$$$$$$$$$$$$$$$$$$$$$$$n,                                   ;$$$    //
//    $$$U                                         l$$$$$$$$$$$$$$$$$$$$$$$$;      k$$$$$$$$$$$$$$$$$$$$$$$$$$$$$-                                     :$$$    //
//    $$$Y                                      ",,. [email protected]$$$$$$$$$$$$$$$$$$$$$' .[   [email protected]$$$$$*  ,,^                                  ,$$$    //
//    [email protected]                                    ^%[email protected][email protected]$$<^$n`[email protected]$$$&{q$$$$$$$$$$$$$Q0$$$$&.                                "$$$    //
//    $$$X                                       L$$$$$$$$$$$$$$$$i,vo$$$$$$$$b$$B$$$$$$$$$$$*< [email protected]$$Q                                   "[email protected]    //
//    $$$z                                         ,?[#$$$$$$$$$$$0   lQ$$$$$$$$$$$$$$$$$BwC.  [email protected]|]I                                     ^$$$    //
//    $$$z                                             '/$$$$$$$$$$"     {$$$$$$$$$$$$$%#:     %$$$$$$$$$$$$$"                                         ^$$$    //
//    $$$z                                               B$$$$$$$$$a       .*&$$$$8Wo!        n$$$$$$$$$$$$$(                                          ^$$$    //
//    $$$z                                               [email protected];                         o$$$$$$$$$$$$$l                                          ^[email protected]    //
//    $$$z                                             .L$$$$$$$$$$$k                        >$$$$$$$$$$$$$$%-                                         ^$$$    //
//    $$$z                                             lB%t$$$$$$$$$$;                       [email protected]                                         ^$$$    //
//    [email protected]                                             .'  .%$$$$$$$$|                      ,%$$$$$$$$$$$U   '                                         ^$$$    //
//    $$$z                                                   [email protected]$$$$$$$&,                   i$$$$$$$$$$$$(                                              ^$$$    //
//    $$$z                                                    $$$$$$$$$$$c.            `~*[email protected]$$$$_                                              ^$$$    //
//    $$$z                                                    v$$$$$$$$$$$$$$8Xznxxn8$$$$$$$$$$$$$$$$$$f                                               ^$$$    //
//    $$$z                                                    :[email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$                                                ^$$$    //
//    $$$z                                                     [email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$8                                                ^$$$    //
//    $$$z                                                     [email protected][email protected]                                                ^$$$    //
//    $$$z                                                      [email protected]$$$$$$$$$$$$$$$$$q                                                 ^$$$    //
//    [email protected]                                                     '&$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$8'                                                ^$$$    //
//    [email protected]$z                                                   '}[email protected][email protected]~'                                              ^$$$    //
//    $$$z                                                 [email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$BU                                            ^$$$    //
//    $$$z                                             .([email protected]^                                         ^$$$    //
//    $$$z                                           [email protected]$$$$$$$$$$$$$$$$%^                                       ^$$$    //
//    $$$z                                      "v/[email protected]@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$q |u'                                  ^$$$    //
//    $$$z                                   `iX[email protected]$$$$wnl.                               ^$$$    //
//    $$$z                       rMZ.      ,&[email protected][email protected][email protected][email protected]@[email protected]      "MaI                    ^[email protected]$    //
//    $$$z                     .h$$$$$$$$$$$$$$$$$$[email protected]$$$$$$$$$$$$$$$%"                   ^$$$    //
//    [email protected]$z                    `[email protected][email protected][email protected][email protected]>.                 ^$$$    //
//    $$$z                  '#[email protected][email protected]$$$$$$$$$$$$$$$$$$B,                ^$$$    //
//    $$$z                  [email protected][email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$m                ^$$$    //
//    $$$z              [email protected][email protected][email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$p            ^$$$    //
//    $$$z       .U|..*[email protected][email protected][email protected]$$$$$$r ;O^      ^$$$    //
//    $$$z    'f%@[email protected][email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$[email protected]B$Br:   ^$$$    //
//    $$$z  [email protected][email protected][email protected][email protected][email protected]$$$$$$$$$hr'^$$$    //
//    $$$%oo$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$[email protected][email protected]*#$$$    //
//    $$$$$$$[email protected][email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UP1 is ERC1155Creator {
    constructor() ERC1155Creator() {}
}