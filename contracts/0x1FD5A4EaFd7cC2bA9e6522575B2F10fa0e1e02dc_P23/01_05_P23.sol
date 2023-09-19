// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 23
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                   .,s#N##Nmm,                                  //
//                                                                                                //
//                                                ,S###############mp,                            //
//                                                                                                //
//                                              s######@#############@##N                         //
//                                                                                                //
//                                             ,#####$##############@#####p                       //
//                                                                                                //
//                                            @@#########@##########@#######,                     //
//                                                                                                //
//                                            ;##############@#########@##@##b                    //
//                                                                                                //
//                                            %########################@######b                   //
//                                                                                                //
//                                            ~"?8b|^^*9|||||777"*##########3%8#N                 //
//                                                                                                //
//                                           |  !9*,,      ^^^     f@#b``^\9^\  L !               //
//                                                                                                //
//                                           . |7C?^         ^,.,   *@#b)|'8p'"^j:{               //
//                                                                                                //
//                                          || !]@WS,,    y#"3ssa ^.+I@##e,sb ^ ^Q@#              //
//                                                                                                //
//                                          |~ '| 9Q,|`o   !QQSWb^ .o\#@#  o    !C@##             //
//                                                                                                //
//                                          I' Gjc ^7"||  8b..    ,GGGi#~ 'G   .*@###\            //
//                                                                                                //
//                                              |*   ^ j  'kO    /LGC' +      .*@#b@#b            //
//                                                                                                //
//                                           ~, **| sQ, ..,*`   7^  .\`[    j o##@#|2D            //
//                                                                                                //
//                                            .j^ ]####N:sss&v# "    U |     `Gb:T?@$N            //
//                                                                                                //
//                                           *S,spdQb##W#z7f7k   '.^~         7*,G#GSGIN~v        //
//                                                                                                //
//                                    '     jb$#S#8SSQ#-dC\-l-.~.` .~~*,$p  .,,#GG8GG$bQp         //
//                                                                                                //
//                              .#b,a,,    (Q#S#GGG$##pbjb^ :ob   j/,*,Q##@###GGGG8G@GGGGb[       //
//                                                                                                //
//                             ~@88GG##SSS##S##GG8Q$#@9b{C`**@*oj2b*,;GQ#Q###lGGGGSGGGGGGZ'       //
//                                                                                                //
//                              pGGSSQQ@##SSG@SS8@##8@8bbL    'Gb^ |/GG@#b##Q##GS@QSGWpG8Gp       //
//                                                                                                //
//                           ;Ca9GGGQ######QGGS$9###G#S#G      *  )]GGGG$######Q#####pG@GGL       //
//                                                                                                //
//                          QGG8S#MW#####QGS@b######$##b*         ~#GG$S@#########TGGGGG$Gb       //
//                                                                                                //
//                        /GGGG####b#fSG#NS#Qb$#G#bGG$#bo        {!G$#$G8G####$GGGGSQGG#bGb       //
//                                                                                                //
//                       @GGGG###N#$b{#@##G@@SSG##b$#G$bL        '/lG@#9GG@##SQGQQGGGS##8pS       //
//                                                                                                //
//                      jGGGG@###9T#;#]###G##GGG$@bSNGGbG          #G@GSG9#Q#bQSGSGGSb#GG#QS      //
//                                                                                                //
//                      @GGG9#QGGGQp#p#Gb#f@GGGGG$S##GGbG        '$GS@#GGG9@#pSQGQGGQb$G8G8b      //
//                                                                                                //
//                      bGG#QQb#@######p#G##@QGS#b##GG9bG*       IGS@bGGG$Q$GTNGGQSG$Q@GGGb#      //
//                                                                                                //
//                      @SG$bQW@G##Q####b@SbbGGQQS#bjG8bGo.   /  #QS@#SGQ##S9GpGSGQGGS#GS@@#b     //
//                                                                                                //
//                      bGS$@9###$####bb$@SGGGS#@@bSSG$bGC*;  Gp@G$Sb#G###@Q#G#GGGGSGQGGG##Qp     //
//                                                                                                //
//                       '@G##G$l@G$$Ca#S${GbS9#@#GGGGbGGCp$~ '|bTG#Qb###Q#Q##GQGGGGGQGG$#G#b     //
//                                                                                                //
//                         `|#NGQQpS#N$NWIG#QS#G###G#GbGSCGG   jGQG#Q##b@#QQ##QGGSQQ#QGG####@     //
//                                                                                                //
//                                       #GGS#G@@##GGGpGG^*|   #8GG3Q###@@SGT##SQGGGQGH##@#$#     //
//                                                                                                //
//                                       WTQ##Sb@#GGGQ+G !     #$Gb]Q###G#$#]$#$#QSQ#G#N'@S9`     //
//                                                                                                //
//                                      `'#S#GG#@#G$G#'C |j   '@GQb@G@##@@Gb#9$G@###Ql#SNsQS      //
//                                                                                                //
//                                       ]SG@##b##8QQD:| j|    !G9SGS#SG#bS#G8QfS@##W#S#####~     //
//                                                                                                //
//                                      '@QQ###S#GGGG^o~  ~    @#$H###G$#{##G$Q~G9G$@##$####b     //
//                                                                                                //
//                                     '!SS##@#@#8bSG b        @bGGGbGG#b###QG# GS8GGG9pQ#b#b     //
//                                                                                                //
//                                     b#Q##b#b#b@Q$S.*        lGGGG!G#####G8Q# GQG@GG@8b###b     //
//                                                                                                //
//                                     #SGS#@###b@Q$S||     ^  7GSGG#G####bG$S# GGGG9G#Q#@#GG     //
//                                                                                                //
//                                    $G#Q@b##@# GGQ#p*       ~!GQG$G###@#Sbb@S]SGGGGG$GG#GWGG    //
//                                                                                                //
//                                    7` ^7""77  ^^^`          '^^^""^7 `7^  '^`^^^^`^^7^ ^^`^    //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract P23 is ERC721Creator {
    constructor() ERC721Creator("23", "P23") {}
}