// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phygital
/// @author: manifold.xyz

import "./ERC721Creator.sol";

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
//                                           |  !9*,,      ^^^     [email protected]#b``^\9^\  L !               //
//                                                                                                //
//                                           . |7C?^         ^,.,   *@#b)|'8p'"^j:{               //
//                                                                                                //
//                                          || !]@WS,,    y#"3ssa ^[email protected]##e,sb ^ ^[email protected]#              //
//                                                                                                //
//                                          |~ '| 9Q,|`o   !QQSWb^ .o\#@#  o    [email protected]##             //
//                                                                                                //
//                                          I' Gjc ^7"||  8b..    ,GGGi#~ 'G   .*@###\            //
//                                                                                                //
//                                              |*   ^ j  'kO    /LGC' +      .*@#[email protected]#b            //
//                                                                                                //
//                                           ~, **| sQ, ..,*`   7^  .\`[    j o##@#|2D            //
//                                                                                                //
//                                            .j^ ]####N:sss&v# "    U |     `Gb:[email protected]$N            //
//                                                                                                //
//                                           *S,spdQb##W#z7f7k   '.^~         7*,G#GSGIN~v        //
//                                                                                                //
//                                    '     jb$#S#8SSQ#-dC\-l-.~.` .~~*,$p  .,,#GG8GG$bQp         //
//                                                                                                //
//                              .#b,a,,    (Q#S#GGG$##pbjb^ :ob   j/,*,Q##@###[email protected][       //
//                                                                                                //
//                             [email protected]##SSS##S##GG8Q$#@9b{C`**@*oj2b*,;GQ#Q###lGGGGSGGGGGGZ'       //
//                                                                                                //
//                              [email protected]##[email protected]@##[email protected]    'Gb^ |/[email protected]#b##Q##[email protected]       //
//                                                                                                //
//                           ;Ca9GGGQ######QGGS$9###G#S#G      *  )]GGGG$######Q#####[email protected]       //
//                                                                                                //
//                          QGG8S#MW#####[email protected]######$##b*         ~#[email protected]#########TGGGGG$Gb       //
//                                                                                                //
//                        /GGGG####b#fSG#NS#Qb$#G#bGG$#bo        {!G$#$G8G####$GGGGSQGG#bGb       //
//                                                                                                //
//                       @GGGG###N#$b{#@##[email protected]@SSG##b$#G$bL        '/[email protected]#[email protected]##SQGQQGGGS##8pS       //
//                                                                                                //
//                      [email protected]###9T#;#]###G##[email protected]          #[email protected]#Q#bQSGSGGSb#GG#QS      //
//                                                                                                //
//                      @GGG9#QGGGQp#p#Gb#[email protected]$S##GGbG        '[email protected]#[email protected]#pSQGQGGQb$G8G8b      //
//                                                                                                //
//                      bGG#QQb#@######p#G##@QGS#b##GG9bG*       [email protected][email protected]#      //
//                                                                                                //
//                      @[email protected]##Q####[email protected]#bjG8bGo.   /  #[email protected]#SGQ##S9GpGSGQGGS#[email protected]@#b     //
//                                                                                                //
//                      [email protected]###$####[email protected]#@@bSSG$bGC*;  [email protected]$Sb#G###@Q#G#GGGGSGQGGG##Qp     //
//                                                                                                //
//                       '@G##[email protected]$$Ca#S${GbS9#@#GGGGbGGCp$~ '|bTG#Qb###Q#Q##GQGGGGGQGG$#G#b     //
//                                                                                                //
//                         `|#NGQQpS#N$NWIG#QS#G###G#GbGSCGG   jGQG#Q##[email protected]#QQ##QGGSQQ#QGG####@     //
//                                                                                                //
//                                       #GGS#[email protected]@##GGGpGG^*|   #8GG3Q###@@SGT##SQGGGQGH##@#$#     //
//                                                                                                //
//                                       WTQ##[email protected]#GGGQ+G !     #$Gb]Q###G#$#]$#$#QSQ#G#N'@S9`     //
//                                                                                                //
//                                      `'#S#GG#@#G$G#'C |j   '@[email protected]@##@@Gb#[email protected]###Ql#SNsQS      //
//                                                                                                //
//                                       ][email protected]##b##8QQD:| j|    !G9SGS#SG#bS#[email protected]##W#S#####~     //
//                                                                                                //
//                                      '@QQ###S#GGGG^o~  ~    @#$H###G$#{##[email protected]##$####b     //
//                                                                                                //
//                                     '!SS##@#@#8bSG b        @bGGGbGG#b###QG# GS8GGG9pQ#b#b     //
//                                                                                                //
//                                     b#Q##b#b#[email protected]$S.*        lGGGG!G#####G8Q# [email protected]@8b###b     //
//                                                                                                //
//                                     #SGS#@###[email protected]$S||     ^  7GSGG#G####bG$S# GGGG9G#Q#@#GG     //
//                                                                                                //
//                                    $G#[email protected]##@# GGQ#p*       ~!GQG$G###@#[email protected]]SGGGGG$GG#GWGG    //
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


contract PHGTL is ERC721Creator {
    constructor() ERC721Creator("Phygital", "PHGTL") {}
}