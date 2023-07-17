// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Proof of Patronage
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                              BBU                                                                             //
//                                                                            [email protected]@B                                                                           //
//                                                                            G:uBirk                                                                           //
//                                                                             :[email protected]                                                                            //
//                                                            .. [email protected] JX       @5   MB      ,qr [email protected] ,.                                                           //
//                                                           :[email protected] 1BN @[email protected]  :[email protected]   [email protected]:[email protected] @[email protected]                                                           //
//                                                        [email protected]::[email protected] OBZ   [email protected]@Br   @BU [email protected]                                                        //
//                                                         [email protected] ,[email protected] :BZ:;iiiiiBB  [email protected] ,[email protected]                                                        //
//                                                       [email protected] @@  [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@BN:  @B [email protected]                                                      //
//                                                       :Pv @7 @@@@[email protected]@[email protected]@@1 [email protected]@G [email protected]@[email protected]@@[email protected]@B [email protected] SS.                                                      //
//                                                        @@[email protected]@[email protected]@@@[email protected]@@[email protected]: B7 ZB [email protected]@[email protected]@[email protected]@[email protected];@LFBE                                                       //
//                                                        NBi [email protected]@@[email protected]@[email protected]@[email protected]@ @@[email protected] @[email protected]@[email protected]@[email protected]@[email protected] [email protected]                                                       //
//                                                         [email protected]@[email protected]@[email protected]@[email protected]@B rJLu. @@[email protected]@@@@[email protected]@@@:[email protected]                                                         //
//                                                          F5i:[email protected]@[email protected]::[email protected] vBJii:[email protected]@[email protected]:7ku                                                         //
//                                                            @Bu LvUq rMBOL :@@@[email protected]@@  uBBG, ZJLr @[email protected]                                                           //
//                                                             .  BBj [email protected]@@@[email protected]@: [email protected]@[email protected]@@@  [email protected]  ,                                                            //
//                                               7;               :[email protected]@B0  [email protected]@Br [email protected]@[email protected]  [email protected]@[email protected]                v:                                              //
//                                              [email protected]               @[email protected]@[email protected]@@[email protected]@[email protected]@@@@@[email protected]@               ,[email protected]                                             //
//                                             OM   JGOF7:.   ..::[email protected]:,   .B   .:[email protected]:,.    ,:LPM07   @u                                            //
//                                            BZ       .:iu52jvLv7:.             @             ..:iL2XSSUYi,       @P                                           //
//                                           BS         .7.             7v       B              LSL                 BO                                          //
//                                          BL         2BB  [email protected]@@[email protected]@   @B      @            :@[email protected]:                EM                                         //
//                                         BU          [email protected]@[email protected]@@[email protected]@[email protected]@@@      B    :[email protected]@B: kB   Bk ,[email protected]@@:         @B                                        //
//                                         :Bi        ..:[email protected]@@[email protected]@[email protected]@@@@EL..     @    [email protected]@[email protected] r   r [email protected]@[email protected]       uM.                                        //
//                                           BY       [email protected]@[email protected]@@@[email protected]@B.    B   [email protected]@[email protected]@7:,.  ,:[email protected]@[email protected]@r      GO                                          //
//                                            @L        ;qU5O,J [email protected] L:B7q5,      @   .BrBrM7 [email protected]@[email protected]@@@q 7MrBrB      ZG                                           //
//                                             B,           @[email protected]@BqBBBr          B    B87Gr [email protected]@[email protected]@@Bq [email protected]     LB                                            //
//                                       . UL  .B            @@@[email protected]@BL           @     @LJ [email protected]@[email protected] [email protected]      @   Pi .                                      //
//                                       [email protected]: . @r           ;@[email protected]@[email protected]            B      @ [email protected] u:.:u [email protected] @      N5   [email protected]                                      //
//                                       F5  @@ :@            BU   Ou            @       [email protected] :M1u1M: [email protected]       @  BP  M7                                      //
//                                     [email protected]  @ZE  B           [email protected]    ,@.           B      @B J7 @@@[email protected]@ 7J [email protected]     ,B  [email protected]  [email protected]                                    //
//                                   [email protected]    @           .EYu2Y15            @      ::   [email protected]@[email protected]   :,     7M    [email protected]@@@8u                                   //
//                                   [email protected]  [email protected]     M:                              B  . .      [email protected]@[email protected]@M          11     [email protected] [email protected]                                  //
//                                  0r: LEi      [email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@@@@[email protected]@@@[email protected]@Br      rM: 775                                 //
//                                 [email protected]       [email protected]@[email protected]@@[email protected]@[email protected]@@@[email protected]@@[email protected]@[email protected]@[email protected]  7B. @Ev [email protected]@@@[email protected]@[email protected]@[email protected]       [email protected]@                                 //
//                                 [email protected]        [email protected] ;[email protected] @[email protected]@[email protected]@[email protected]@[email protected] 7:[email protected]:[email protected] [email protected]:[email protected]    [email protected]@Bv        [email protected]                                //
//                              .jFB  Y:         [email protected]@i    [email protected]    [email protected]@[email protected]@[email protected]@[email protected],@B.M2vEi OBu   @58:k   @M Y [email protected]         7r  BJL                              //
//                               [email protected]  ,B,         @[email protected]  ,[email protected],  [email protected]@j          @ [email protected]@[email protected] [email protected]  :[email protected],   [email protected]: [email protected]         vB  :B,                              //
//                               :L  B7i        [email protected]@@[email protected]@[email protected]@@@[email protected]@@Bj          B .vO,[email protected] [email protected]@: 8:     qB :[email protected]         ;2B  5                               //
//                               @[email protected]          [email protected]@[email protected]@BqB  @[email protected]@@@[email protected]          @    :  Z5 [email protected]@@@B       B:7.B [email protected]          [email protected]@@                              //
//                              [email protected]@E          @@@[email protected]@[email protected]    [email protected]@[email protected],rri:i,,.;B     .S,v OBX ir        @Ei,i: [email protected]          @@BM1k                             //
//                              Mu iJL         [email protected]@[email protected]@[email protected]  [email protected]@[email protected]@q.::vU:M2v:@@@[email protected]@[email protected]@[email protected]   [email protected]@L:  [email protected] ,@[email protected]@.         uJ  PZ                             //
//                             Lj: vM          @@[email protected]@@[email protected]@[email protected]@[email protected]@@[email protected]   [email protected] [email protected]@[email protected]@[email protected]@[email protected]@Bu.   B   v7 :@@[email protected]         :M: 7U;                            //
//                             [email protected]         [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@  @[email protected] @[email protected]@[email protected]@@@[email protected]@[email protected] [email protected]  [email protected]  :[email protected]@@j        ,[email protected]:                            //
//                             ,@[email protected]        [email protected]@[email protected]@[email protected]@@@U  [email protected]@@@[email protected] [email protected]: [email protected]@@@[email protected]@[email protected]: :[email protected]  [email protected]@@@[email protected]@@:        [email protected]@                             //
//                             .M  M        [email protected]@[email protected],@[email protected]    [email protected]@B:[email protected]@0 :[email protected],:B        [email protected]@@Bi   [email protected]@@7 :[email protected]@[email protected]@[email protected]       :N  @                             //
//                            JB8  [email protected]     [email protected]@@[email protected]@,   BB1      [email protected]   ,@[email protected] . EPrB      [email protected]@[email protected]  [email protected]@@j   [email protected]@@[email protected]@@[email protected]@:     [email protected]  @Br                           //
//                             :B  @.     [email protected]@[email protected]      :        ,      [email protected]@M::   @   [email protected]@@@[email protected]@[email protected]@[email protected], [email protected]@[email protected]@[email protected]@[email protected]     rq  B                             //
//                              Oj1BY   [email protected]@[email protected]@@: :ii:    ,:ii:    .::[email protected]@@@@@[email protected]@[email protected]@@@@@@@@[email protected]@[email protected]@@@[email protected]@[email protected]@@[email protected]@@@@Br   8G1J8                             //
//                             ,[email protected]@M   [email protected];  ...:[email protected]@[email protected]:i;:@[email protected]:i:[email protected]@u.:[email protected]                           ... .    [email protected]  ,@@[email protected]                             //
//                             7u; :Oi    Mi          @[email protected]    @@[email protected]    @[email protected]    B @0.         :E:.          [email protected]       jq    JN. rk:                            //
//                              0M  5L     @S         [email protected]@@J    @@@@J    [email protected]@7    @  [email protected]@[email protected]@: [email protected]@@B:  [email protected]@[email protected]@B       B0     JS  @u                             //
//                              kYuE8B      @v        @[email protected]    [email protected]@L    @[email protected]    @ ,  ,[email protected] [email protected]  [email protected]@B87,  :     OM      BZEY5J                             //
//                               @[email protected]@       @        [email protected]@j    @[email protected]    [email protected]@v    @ [email protected]@@[email protected] .  [email protected]   [email protected]@[email protected]    :@      [email protected]@BB                              //
//                               .k  KN:.    P8       @[email protected]@u    [email protected]@L    @[email protected]    B    :[email protected]@[email protected]@[email protected]@B05u7:     @i    ,,@r .k                               //
//                                @q  [email protected]      B       [email protected]@@j    @[email protected]    [email protected]@v    @  [email protected]@[email protected]@r [email protected]@BBL     @      @O  @0                               //
//                               r8B7 :J      @       @[email protected]@u    @@[email protected]    @[email protected]    B     ,[email protected]: [email protected]       [email protected]      U  SB8:                              //
//                                 :[email protected]@.    Bk   [email protected]@j    @[email protected]    [email protected]@v    @     7uu:   [email protected]@@[email protected]:  r:  rOi.   @P    :[email protected]                                 //
//                                  [email protected]:    vXXq2i,@@@Bu    [email protected]@L    @[email protected]    B         ,[email protected]@[email protected]@[email protected]  @:75PXSr    [email protected]                                 //
//                                  ,Gr  O2:          [email protected]@@J    @[email protected]    @@@@v    @    [email protected]@[email protected]@B.X Lr:P @i          iXS .;M                                  //
//                                    @X ,YB.          [email protected]    [email protected]@Y    @[email protected]@L    B    7BG:51 u  @B:  r1   @v          7B7  MG                                   //
//                                    [email protected]@N           ,@B    @[email protected]    [email protected]@v    @     v        [email protected]@BG  [email protected]:          :[email protected]@EP.                                   //
//                                      MBr :BBF          NBr  @@@@L    @[email protected]@L    B           [email protected]@FB    rBX          [email protected]  [email protected]                                     //
//                                        SL  BS           [email protected]@BJ    @@[email protected]    @         @[email protected]   .uMu            @q  EL                                       //
//                                        @BN  [email protected],           :[email protected]@P    @[email protected]    B         Y    ijG1:           :[email protected] [email protected]                                       //
//                                        . [email protected]              iqXu: @@[email protected]    @          :uXPv,            :[email protected]@5N: .                                       //
//                                            @BL  kLS:              :[email protected]@@BL    B      :uZPY,              7uSL .YBM                                           //
//                                             [email protected], [email protected] :               [email protected]   @   iXG2i             ., ,[email protected] [email protected]                                            //
//                                               [email protected] @[email protected]                .kMi B LBF:                [email protected] [email protected]                                              //
//                                                 :FFii  77JZ7:               [email protected]              .:L8ru,  7:0u.                                                //
//                                                    :Bq8  @[email protected]    :        :        :    [email protected];@[email protected] :[email protected]@.                                                   //
//                                                     5.:[email protected]:  [email protected]:   [email protected]   :[email protected];:  [email protected],,u                                                    //
//                                                          [email protected]@@ :  X:  [email protected]@k [email protected]  7F  . @[email protected]:                                                         //
//                                                              rLkBrU8.7v  [email protected]:[email protected]@7  Ui:B7uMSvi                                                             //
//                                                                    [email protected] [email protected]@[email protected]@7 :YLB,                                                                   //
//                                                                           [email protected] [email protected]                                                                          //
//                                                                             2: j:                                                                            //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Lobkowicz is ERC721Creator {
    constructor() ERC721Creator("Proof of Patronage", "Lobkowicz") {}
}