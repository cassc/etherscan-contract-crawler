// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dholl.Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                               .                                                  //
//                                               `<[}.        ./Mx1'                                                //
//                                              [email protected]~WE_ARE   '' [email protected]?                                              //
//                                      .;]'..."+&$$$$%'. )@@$$*`                                                   //
//                                     "&$>'`[email protected]$B$B-DHOLL-n;;j^                                              //
//                                  .}[email protected]'                                              //
//                              .'...<-DHOLL--DHOLL--DHOLL--DHOLL-$$$BW8%u)l'                                       //
//                             .#$B~(-DHOLL--DHOLL--DHOLL--DHOLL--DHOLL--DHOLL-$j'                                  //
//                            `[email protected]$$%%$$$$&W&&[email protected]$$$%i                                 //
//                            x-DHOLL--DHOLL-$*<,,{j8$n.      ``,]&[email protected]                               //
//                    '.  ..`(-DHOLL-$$$M&1:`'     `,`'^``'.       ':{B-DHOLL-DHOLL$_                               //
//                     /-DHOLL-DHOLL$&<'.                  ...''      .}&-DHOLL-$$$$%l'.I                           //
//                   .,[email protected]>                           ^^.      <@-DHOLL--DHOLL-.                          //
//                :)v-DHOLL-DHOLL$j'  '",:"`'.                    '^'.'```!-DHOLL-$$$$z(>.                          //
//               .,,W-DHOLL-$$$$#,^]rrrf|{-|$$&l                .,;]*[email protected]     .                        //
//                  ^-DHOLL-$$%t{M8$$%[email protected]$W\`           `>t1B-DHOLL--DHOLL-DHOLL`.`~&$v;.                     //
//                 "r-DHOLL-$$)[email protected])^ .   'iWDHOLLBi         >-|r%$z_:`'.`\W-DHOLL--DHOLL-$/                        //
//                 f-DHOLL-$$~:$$).          >tB$$$,_       [email protected]$M,       }"]?*-DHOLL-DHOLL$1;".                    //
//                  [email protected]" W$(              `8$$[,:     .8j$$]         l ..^{-DHOLL--DHOLL-$<                    //
//                  `DHOLL$( >$$<`              [email protected]^z     "jM$B.         :     ^-DHOLL-$$+`....                    //
//                .)@DHOLL$+.&[email protected]_              [$$$%}     '\%$$^      .'',     .-DHOLL-$v                          //
//               .W-DHOLL-8..B$$$8            .rDHOLL#'     z[$$*'        ,     ,[email protected]:                         //
//               |-DHOLL-$t .i$$$$-          'u-DHOLL-#l'   !)$$$%;      .`    :B-DHOLL-$$$8},'                     //
//               @u&DHOLL$i   /$$$$x!^'''^,-*-DHOLL-$B_`.    )DHOLLz>`.  ^   '#[email protected]$ui                  //
//               .  (DHOLL-`   "c-DHOLL--DHOLL-$$$$j,'        :#[email protected]&[email protected]`B-DHOLL-$$$u}(|{.                 //
//                  'DHOLL&i'    [email protected]@DHOLLWj#$$n<.             `n-DHOLL-$$$W/`.;i-DHOLL-$$$$r                      //
//            .  'I?*DHOLL$W^.   \$x;i~_<;+_{_;'                  ';*$%$$$%!^  ;'M-DHOLL-DHOLL<                     //
//           `' .v-DHOLL-$$$v:  l$$` '^"^``.                        ..<1$$W^. '?#-DHOLL-$(`.'^;                     //
//           .?*-DHOLL-DHOLL$#I'@$*'                                 '^ j$*  .vB-DHOLL-$W.                          //
//               .'`:|@-DHOLL-$8$$B^                                "`. ($) .n-DHOLL-$c^                            //
//                    '#-DHOLL-$$$$~                              ```'  &$l;W-DHOLL-$$^                             //
//                     f-DHOLL-$$$$r  .^.    "`  . ^?>'  ^I.   ,^  `.l ,-DHOLL-DHOLL$M;                             //
//                    ^%@-DHOLL-$$$%l;}$W{)|\[email protected]&@$r[_c&},>rf%l#-DHOLL-$$$$u.                               //
//                   .^..x-DHOLL--DHOLL-DHOLL&W$zW$$Bz#&[email protected]$$$$t                                //
//                       ."[email protected]$$$$B\+"`...'"?zj><:^^```:+]]#[email protected]$$n*,                               //
//                         .:l<^ltB-DHOLL-DHOLL%DHOLLt-{(~;.'^|v*-DHOLL-$$$u'  ^c# 'v                               //
//                                 ,B-DHOLL--DHOLL--DHOLL--DHOLL--DHOLL-M8$#.    '  .                               //
//                                  `&$$#zr*-DHOLL--DHOLL--DHOLL--DHOLL-v.'"`                                       //
//                                   .x{   `-DHOLL--DHOLL--DHOLL-Bj]_<;|$]                                          //
//                                         [email protected]>.      ;z                                          //
//                                         ^{r8$$x#$$$$Bu$$$$$M'         v                                          //
//                                              `;;i?,`.{$$$$Bl                                                     //
//                                                       .`~\u)                                                     //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DHOLL is ERC721Creator {
    constructor() ERC721Creator("Dholl.Art", "DHOLL") {}
}