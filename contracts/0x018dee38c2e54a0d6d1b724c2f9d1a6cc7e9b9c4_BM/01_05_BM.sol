// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bryan Minear | The Legacy Art Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                   ##                                                                      //
//                                                                            m     @###Q       ##                                                           //
//                                                                                 ]#[email protected]%m                @#m                                                //
//                                                                  #b             #GlG#p^@p             #####m                                              //
//                                                                              em#bQQQ8#  %m            '@##^                                               //
//                                                       #                     #[email protected]  "#             "                                                 //
//                                                      @##_                  @bGGGGGGGG7#    @m                              %b                             //
//                                                       7                   @#""[email protected]    "#                                                            //
//                                          ]#                              @#GGGGGGGGGGGG#p    '@p                                                          //
//                                                               #         @#*sssssssssssS8#      7#          j#                                             //
//                                                                        ;#*[email protected]      '@Q                         %#_                           //
//                                                         ,             ]#^[email protected]#.        %m             ###Q                                     //
//                                                       ,####,      ##m,#.G^^^^^^|||||||#b           ^@p ,s#     ;#[email protected]##                                    //
//                                                      ##[email protected] [email protected]  ,#b^|5,^^^:*GGGGGGGG;#\              %#[email protected]#@m ,#[email protected]@m                                  //
//                                      ]#p           ;#b##@#   |@m#b%WWWWWWWWWWWWWWWCG||7775####        "##b 7##'*GGGlG# 7#,         ,#m        7\          //
//                                                  ,#GG###@#    /#`^^^^^^^^^^^^^^^^^^^^^^**Gs#\           7    @Q')eee###  %N        "##.                   //
//                                                 ##G####[email protected]#   ##j,,,,,,,,,,,,,,,QQQQQQQp*s#\                   "#p*[email protected]#  "@p                             //
//                                               ;#bQQQ#Q##|   #b  `````````....~~^^^^||`s#^                       @p*[email protected]   ^^7#,                         //
//                         m               #m, ,#GGGGGQ#M`    #b                      [email protected]#^                         j#||?||[email protected]      %m                        //
//                                       ,#bGG75GGGlQ#M.    ,#"_`^^^^^^^^^^^^^""""""\#M"                            '%#`GGG"#       7#  ,,m      ,           //
//                                     ,#C^755555GQ#O      ;#`_ _____             ,#M`                                "@Q*WW7#  ,,    %T^`7#     `           //
//                                    ##*GGGGGGGG{55555555## :mmmmmmmmmmmmmmmmmm,#M`                                    7#[email protected]        ^@p               //
//                                  ,#b,QQQQQQQQQQQQQQQSG#b          _  _ ____,#O                                        ^@QG,QQQ8#          @m              //
//                                 #b*GGGGGGGGGGGGGGGGGj#^              ___ ;#C                    ,                       7#p*GGl#           7#             //
//                               s#~:GGGGGGGGGy#7%###Qs#` ````````````````,#"             ,ae###W57"%N                      '@[email protected]           ^#,           //
//                             ,#b.'7777777|;#C       ~                   j#    ,,em##W57|`"___ _____|@Q                      "#[email protected]#             @Q          //
//                            #M.^'^^*^^:G;#C """""""""""""""""""""""""""_ #W5"7^|      "7777777""""___7#                       @Q^#              %#         //
//                    s##W5777| WWWWWWM^,#C                                                             '%                       7##b              "#        //
//                  ;#|___         _'^,#C                                                                 _                        %Q                @Q      //
//                ;#T    __ _,,,_   ,#C    ##%%%#  ##WWW#p"#,  #"  ##Q   ##p  j#    ##p  ,##  #  ##,  @# @#WWWWb  ,##   j#WWWW#     "#,               %m     //
//               #"    '.~^,||``. ,#C      ##WWW#J #mmmm#b  %M#\  #Q @b  @[email protected]#    #b%##Mj#  #  # 7#[email protected]# @####b  ;#,j#p j#mmm##"      %m               "#    //
//                          ___ ,#C        #Mmmm#C #b  "#p   #~ ,#^|||\# @b  "@#    #b  ` j#  #  #   "@# @#####[email protected]#|||`@pj#_  %#        7#,                   //
//                     "77777 ,#M                                                                                                        %N                  //
//                          ,#M   WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW                                 "@p                //
//                          7`                                 #Q                                         #                                 7b               //
//                     ,mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm  \#w7  emmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm  ",@Q" smmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm           //
//                                        ,                  ",@W|_               #  b jp               ";@w"                  ,                             //
//                                       #]"Q                7,@%,"              ]b  `  #               ";@w7_               ,#@%,                           //
//                                      ",@% "               ^ #m.`              @_  b  @               `,@Q|_              ^[email protected] `                          //
//                                     s\ #p^\                 ]_                b   `  ^b                @                 m^,#p"W                          //
//                                      #`] "p                                  @   jb   @                                  ,#`@ %,                          //
//                                     ` #{7m_"                                 #   jb   jb                                 `,[email protected]"p                           //
//                                     "^ #p_`=             ,               ]###M########m###m               #              "_ #  "=                         //
//                                       "] *              #@7Q             #-       p       @p            ,[email protected]              "@^~                           //
//                                        ]              ;C ] ^%,          ]#       jb       j#          ,M` @  %p             @                             //
//                                                     s"  ,#W  ^%         #        jb        @p        5   #@@   7                                          //
//                                                       ,#^]~7m          @b                   #          #\ @ |W                                            //
//                                                     ,#|  @Q _"W        #          c         @b      ,#|  ,#p  ^%,                                         //
//                                                    7   ;[email protected]@   "_     @~         jb          @      `  ,#`@'%                                             //
//                                                      ,M, ]  |W       {M          jb          ^#      ,#"  @  |%                                           //
//                                                    ;M`  ,@#   ^%,    #           jb           @b   .M^   #@%   "%p                                        //
//                                                       ,#`]_7m       #~                         @p      #\ @ 7W                                            //
//                                                     ,M,  ]  _"W    @b             p            ^#   ,#|   @   ^%p                                         //
//                                                    7    ,##    '" ]#             jb             "# "`    #@@     ^                                        //
//                                                        #"]~7Q    ,#              jb              \b    ;" @ 7p                                            //
//                                                       .  ]       #`              jb               @p      @                                               //
//                                                          ]      #"                                 @p     @                                               //
//                                                          ]     #^                                   @p    8                                               //
//                                                               #"                 jb                  @                                                    //
//                                                              ^|                  jb                   7                                                   //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BM is ERC721Creator {
    constructor() ERC721Creator("Bryan Minear | The Legacy Art Collection", "BM") {}
}