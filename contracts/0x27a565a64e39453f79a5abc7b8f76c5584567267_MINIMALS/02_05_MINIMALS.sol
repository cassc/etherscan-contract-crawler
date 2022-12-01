// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minimals
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//        $$$$$KPPZ5l%l]ZPlI5l[l][9[l%UZIIll]%%PPPPHlZllll]llZ9l%%PZ]l5l[llll]l%P5PIllllllllZl%Zl%5I5l%l%$$$$$    //
//        $$$$$C  !     '``'         ;       ||`|              `|``'    '     :| '           !`    '     $$$$$    //
//        $$$$$U'   `   '`'`         ! `'   '|L,  `     ,,,,,   |`' `         ;`  `          '`   `' `   $$$$$    //
//        $$$$$w  !`    ',,'      `  !  '    |||!'!;!!||||||!||;!\;`   '      '!  `          ',    '     $$$$$    //
//        $$$$$U `'`     '!'      `  ''`     ",.=||~'*=  !,. , ;j|'`v  :`     '``             `   `'  `  $$$$$    //
//        $$$$$C  '      '`'         !!'!    .,`'! ,r,',  ' ,'` .!'  ;: >,    :!             '''   '  `  $$$$$    //
//        $$$$$U  `      ``|         ! `   ;[L,|;!;;;Lj,|),,r,!=~` ;`} ; '    '`              '    '     $$$$$    //
//        $$$$$U` ,     '`''         '   ;=!~,[email protected]@@@@pgpgg|g|||;;;;,;,    '~:|'                  '     $$$$$    //
//        $$$$$U  '     :` '         ! ,|r*'|g$$$$$$$$$$$$    @&&@@@@@@gpp,  '!|`             `    ''   ,$$$$$    //
//        $$$$$w `'`  ' ' `,`        /,wr|;j $$$$$$$$$$$$$$$$$$$$ @@@@@@@@pp  ,|`            ::`  `'`` ' $$$$$    //
//        $$$$$U  .      `  `       ';|/||] $$$$$$$$$$$$$$$$$&$&$ &@@@@@@[email protected]   ,,                 ,     $$$$$    //
//        $$$$$C  :'   `''          j|i|{#@$$$$$$$$$$$$$$$$$$$$$$ @@@@@@@@@@@L | '            ``         $$$$$    //
//        $$$$$C  ' '`   ` '`       r|}|l#@[email protected]@%$B$$&$&[email protected]@@@N%%%@H%[email protected]  `                  '     $$$$$    //
//        $$$$$C `'     '''         \{||##[email protected] $$&[email protected]@&@@ $$$ @N%kl||gg|||]%k%p    ,                      $$$$$    //
//        $$$$$C        , '`        \j||| [email protected]%%%%%%@&$$$ @k||]M%MMNHmgi%%%`   |          :        '  $$$$$    //
//        $$$$$C  '      `   `       ||}j$$$$$&@ [email protected][email protected]@@$&$$ @k|/]W%|@@p|%km%br   |`          ,    '`    $$$$$    //
//        $$$$$C  '      ' '         |'!j$$$$$$$$$& @@  $$$$&@@pg%%%#g%[email protected]%g%%h   `             `  ' `   $$$$$    //
//        $$$$$U  '      '`          |||[email protected]@b%%m%@@@@@@@@@%@  '                  `    $$$$$    //
//        $$$$$C       ':`           [email protected]|4$$$$$$$$$$$$$$$$$$$$ %bg%%%@@@@@@[email protected]%  ''                      $$$$$    //
//        $$$$$C  '    `'``` `      j pj#[email protected]@[email protected][email protected]@%*]%}j%%%@@@N%%%%k :|K          ''          $$$$$    //
//        $$$$$C       ': '         " @@#&[email protected] [email protected][email protected]@@pvji|]@@@@@@N%k%%k j|%                     '$$$$$    //
//        $$$$$C        ' `           [email protected] &&&[email protected]@[email protected]&@%@@i%%@%@@@@@@%%%%k|`][email protected]                      $$$$$    //
//        $$$$$U   `     `  '        `$& &[email protected]@@@@&@@@[email protected]@pj%%%@@@%%%kk%i%j##`                      $$$$$    //
//        $$$$$C  '        ' `        $$ @$&[email protected]   %M%%%ii|l||jk#@@Nkjkkklk%@Y`                 `   `$$$$$    //
//        $$$$$C  :   `  ```          ][email protected] $$$&[email protected]@$ &$ @@@NNHm|%@@@%ilk]jiLkH                        $$$$$    //
//        $$$$$C  :      ` ' :        ``] @[email protected]$$$$&&@[email protected]%||||||j%ki%%kii#%lkk*%:                   `    $$$$$    //
//        $$$$$=  '      !``,           '$ $$$&&&& @@@$$$ @@ggggggkkkkkijl%l%` |. `            '         $$$$$    //
//        $$$$$r         ``  `        ` ',[email protected]@$&$$&@@  @$$&@%@N%ij%kk|||||jlk`  ||``                      $$$$$    //
//        $$$$$r   `         '           ;&@@  @ @@@@@@@& @@%%Ml|||!|||!|l%   ;|L              `         $$$$$    //
//        $$$$$C          `  '          [email protected]@@@@@@%@[email protected]@%%%MQi|||||||||||j`   '|`                   `    $$$$$    //
//        $$$$$C          `          )gw|$$$ @@@@@@%%gM||Yi|||!"'',||||||C     |                         $$$$$    //
//        $$$$$C          `   `     /@  @@[email protected]@%@@@@@@@gWj||;||||||||||%     '|`   '`              `    $$$$$    //
//        $$$$$U         !'' '     gg%%&[email protected][email protected][email protected]@@@%@[email protected]||||||||l!|%C      |`                   `    $$$$$    //
//        $$$$$C         '        @$  & [email protected]&[email protected][email protected]@@@@@@@@pgp|||||l|jj%       ||:                   '   $$$$$    //
//        $$$$$C         ';;;ymMMWF&@@@[email protected] [email protected]@%%$$&@@@@@@@@@@plll{l|j%U      `||              `    `    $$$$$    //
//        $$$$$C  '   ',[email protected]@@|Y!]U#wjg%@$$$R%@@@@%@%N$$ @@@@@@HHkljl%j%@''\     |`                   `    $$$$$    //
//        $$$$$w  ,[email protected]@   N @ [email protected]|%MH!|%|[email protected] @@@@[email protected]&@@%%@@@@@g|ji%%m%` `;",  '|`                   :    $$$$$    //
//        [email protected]@[email protected]%vQ%[email protected]@M!;*,,,|Ww||[email protected]||#$&[email protected]@N%@@@p%%%%%kk%%%%[`  ' ,M,'|`                   '    $$$$$    //
//        [email protected] &@ Ng|[email protected]]w!!]@@@%@g;'||;||%@ki%@[email protected][email protected][email protected]@%@%jj%%%k%L   `;[email protected]%w;                   ,    $$$$$    //
//        [email protected]$$&@@ggi%@h|#||%@[email protected]@@|jkk|j|%|i% [email protected]$$ @@@| "%%%%kk!   ;g% @ "r"v                 '    $$$$$    //
//        [email protected][email protected][email protected] @@k#[email protected]@$wg%@[email protected]||@# @% [email protected] @[      |j%||~',|% @Y !"'!!\,                   $$$$$    //
//        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    //
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MINIMALS is ERC1155Creator {
    constructor() ERC1155Creator() {}
}