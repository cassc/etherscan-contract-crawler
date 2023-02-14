// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 4ever Rose
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                  :[email protected]                                                                       //
//                                                                                [email protected]@@@[email protected]                                                                      //
//                                                                              [email protected]   :[email protected]     ,:                                                             //
//                                                                            ,@BE        :@7 [email protected]@[email protected]@@0i                                                        //
//                                                                           [email protected]            @@@U.   [email protected]@Bqi                                                    //
//                                                                         [email protected]            :BZ          [email protected]@BEj7::,..                                         //
//                                                                       [email protected]             ;Bv                [email protected]@[email protected]                                  //
//                                                                      [email protected]              iBr                              [email protected]@X                               //
//                                                                    MBB     7NO80F1uuLvZr          [email protected]@BEL:                  [email protected]@q                             //
//                                                                 ;[email protected]    [email protected]                  :[email protected]  .riirrr;               [email protected]                            //
//                                                             [email protected]     [email protected]         :[email protected]@[email protected]@[email protected]     .UGu  ..    :Nv         @Bi                           //
//                                                   [email protected]@@@[email protected]      YBj     .vEOMPu;:.        JBr       MB         [email protected]        [email protected]                           //
//                                                [email protected]@@@[email protected]:.         LB7    vMZY,         .rvr    BE       @@         @5      [email protected]                            //
//                                              [email protected]@v.           [email protected]@MOBi   .B2          ,[email protected]@[email protected]   @L      [email protected]         @B      @@L                            //
//                                             [email protected]              :[email protected]:[email protected];  @:         ,Xqi     [email protected]  [email protected]      UB         BL     @BP                             //
//                                            [email protected]                @B      [email protected]                  @BuX8BM      BB        [email protected]     @Bk                              //
//                                           [email protected]                 ,@:   Li  [email protected]:            [email protected]@L :@i     :@:       [email protected]     @B2                               //
//                                           [email protected]                  ,@v   :ur   [email protected]@@[email protected]@@[email protected]@@[email protected]    @B      @B       [email protected]     @BX                                //
//                                            [email protected]:                  @G    :Uv      .::rii:,         @B      [email protected]     :[email protected]     MBM                                 //
//                                             [email protected]:,             NB.    :NL              :    [email protected]      ;BM     0BZ     [email protected]@                                  //
//                                            :[email protected]@@[email protected]@[email protected]@@8U:        iBv     7O5          7k:  [email protected]       @@    :@Bi      [email protected]                               //
//                                          [email protected]@1.         [email protected]:      B0      7BM2i,,iUOZr   OBk        [email protected]   [email protected]       [email protected],[email protected]@@,                            //
//                                        :[email protected]                [email protected]    BZ       ,YGMMqL    [email protected]         [email protected]  [email protected]       [email protected]      [email protected]@                           //
//                                       [email protected]                     ;[email protected]:  Br               [email protected]        [email protected] B:[email protected]         @Bi       [email protected]:                         //
//                                      [email protected]                          [email protected]             :@B,       [email protected],   @Bu         SBM          [email protected]                        //
//                                      [email protected]   ,[email protected]       [email protected]           [email protected]:     [email protected]      :@         [email protected]            :@B                       //
//                                      [email protected]:[email protected]      ,iv1u:       [email protected]      [email protected]    ,[email protected]:          [email protected]        [email protected]              @B                      //
//                                                     [email protected]@7        :J         [email protected]   BX    uBM7               [email protected]      [email protected]                @B.                    //
//                                                       [email protected]                    [email protected]   [email protected]                  UBu    [email protected]                  @B.                   //
//                                                   .:[email protected]@B                      qBY .Bj                    [email protected]   [email protected]                    @M                   //
//                                             [email protected]@@@Bkr ,@B                       [email protected]                     [email protected]  [email protected]                    FBN                   //
//                                         :[email protected]@BMJ:        [email protected]                        :[email protected]                  :[email protected]@:                    MBM                    //
//                                      [email protected]@Bi              [email protected]                          ,8BF                [email protected]                   [email protected];                     //
//                                      [email protected]@@                 BX                            [email protected]           ,[email protected]                     [email protected]@:                       //
//                                        [email protected]@O                [email protected]                              :[email protected]      [email protected]                   [email protected]                          //
//                                          [email protected]               @7                                ,[email protected]@[email protected]                  [email protected]                            //
//                                            [email protected]            [email protected]                                     :[email protected],                 [email protected]                               //
//                                              :@[email protected],           @.                                        [email protected]               [email protected]@,                                 //
//                                                [email protected]:         MM                                        kB              @@:  :[email protected]   [email protected]  :ri5O:        .    //
//                                                   @[email protected]        @                                        [email protected]            [email protected] :8BS.OB.FP7. OBUkv:1M.   .:rikBk    //
//                                                    :[email protected]       [email protected]                                       @[email protected]:.   [email protected]   [email protected]    .8:   BB7rUu5ui.YBu     //
//                                                      [email protected]      B7                                     5B. [email protected]@@@[email protected]@[email protected]                   .    ,  .NP       //
//                                                        @BM      @r                                 [email protected]          @, [email protected]     u:     :u         ..:iUOq.        //
//                                                         [email protected]     @E                          [email protected];           @.  r.     B      @     iL52L,vB8i           //
//                                                          [email protected]     [email protected]                 :[email protected]@[email protected]@1            @.  :      S1     kB rXZNYi     ;[email protected]         //
//                                                            [email protected]      [email protected]:,::[email protected]@@[email protected]@[email protected]            @i  vY      @  [email protected]     i,.::Y0J          //
//                                                              0BM:      [email protected]@[email protected]@[email protected]:        [email protected]@8           @M   Zi    .OBXu5v:    ijr.   [email protected]@i              //
//                                                                [email protected]@[email protected]@@ZL.                   [email protected]         ;B    @, LMBOvuBU          .     iGk             //
//                                                                    .,,                          :@B         BP   :@@FL,     7Mq:    ., .:r7uuujr             //
//                                                                                                  [email protected]       [email protected]  [email protected]@5         :FEr  :BP:7vLi,                //
//                                                                                                  [email protected]       7B1BS    [email protected]          i   :Bi                     //
//                                                                                       ::i::.      @B       [email protected]        ;Eu   ..        [email protected]@:                   //
//                                    ,                                                 iv7rr72qO2   [email protected]    .BZ [email protected]       .7  [email protected]@@[email protected]                      //
//                                    @@qEUr      :;                                             @B1 .BO   [email protected]    [email protected]:       @@                              //
//                              .      Bv ;SBBEr   [email protected]                                           @BO @B  [email protected]         [email protected]@[email protected]                              //
//                         [email protected]@@     iEBM,@,[email protected]                                         :@[email protected]@ [email protected]   .LuUY7:                                           //
//                          8B         .r   .    :[email protected]   vBP   :                                     [email protected]@[email protected]  [email protected]::ij:                                          //
//                iiLUujvr:  SB     .        :i     :     [email protected] [email protected]      iS:                            [email protected]@M.                                                  //
//                @[email protected]    ,ii       :k            [email protected]      @1ku. @B;                     [email protected]@,                                                    //
//                 @u          :      ,2.      .B        .i  iN  @j     7i :[email protected]:[email protected]   .            [email protected]                                                      //
//        [email protected]     .,.          8:      :B        7i     [email protected]      u.  i   [email protected] ,1i2B,           GBM                                 .ik. [email protected]  .:ir8,    //
//    ,[email protected],..,::v.       .rr         @.      uB        X.     [email protected] 7  BU2  .     ,   iB E:          [email protected]                          [email protected],[email protected];LL,[email protected]@B     //
//      ZB,    ..              .k,       [email protected]       @L        M      B1B7 .v     , .    .    G G        @BX                     L  5MrYBi,  ,B:    1v .   1G      //
//        28L     .,:::;;rrr;i:[email protected]       qM      ,@        NL     @BXB ,Uu  . .iM:   i  .  BZP       [email protected]                   [email protected]@UB7                 .  .X;       //
//          iU1i                :[email protected]:  B,      BG       .B     ,  @8:ZY:    ..:. v:  r. . 2i      @BF                 [email protected];      :.    ,    ,i :q7         //
//             [email protected]           .vS:     [email protected],  ,@        @r        @ .         ;qq   P     q:.    @@u              r [email protected] .   .    r    ,:  ,i,  r0vSF       //
//         [email protected]@7.        ..ir7.         [email protected]  ,[email protected]       [email protected]        [email protected]  .,::i:ri  5i   , [email protected]   [email protected]             [email protected]       :    v    L  i.      .Bi       //
//           :[email protected]       ...           ,BM         @B7J0PUi  iB        :B:S:          r0F   ,:  u:   [email protected]@v             B.O  :    ::   ,u    MO7.     .Uj         //
//              :FM8U:               .kZ:        [email protected]     :[email protected];        @. i:   ..:i7vvXr   5  [email protected]    [email protected]            r5   7.    L:    M  .r::... .vF7           //
//                  ,[email protected]         :JU,         [email protected]:          @BPG0r     BJ ,EF           i O.  jBi   [email protected];          [email protected],   1.    Jv    B7:.       rBOvOv         //
//               [email protected]      .:i7:          JBJ          [email protected]@   [email protected]  @u  PBr       ..:[email protected]    1    [email protected];          OOG,   Z:    ;M  .iUM2i,         7B          //
//                 ,[email protected]      .,.           7qv           [email protected]       ,[email protected]    7L, .::irri.,J   O     @[email protected]          @:     Pu     @:::    ,:ii:,.   v7           //
//                    :28Pv.             .r7:           [email protected]            [email protected]@U    @M         iL.M      [email protected]@i          Bi     7B   ,[email protected]:           .Li             //
//                        ,rJZF,     ..,,,            [email protected]           ,BO  [email protected]@L  .:i1E...,::[email protected]       @[email protected]          @7      @::7i   .711J;:.     iZk1.           //
//                        [email protected]                     iZ0.            MBr      [email protected]@:   :::i:: .B      [email protected]          @q   [email protected]         ,,:.    :Lqi            //
//                        ,rjJjSFu7i.            .;u7             [email protected]          :[email protected]:        EB     [email protected]@7          8B.r5j:   :U57,           rU5;               //
//                              ,[email protected]    :::          i.  [email protected]               [email protected]@N.      @E    :BBBL       :[email protected]@[email protected]         .:i:,     [email protected]                  //
//                                   :[email protected]     .   .r.   [email protected]@[email protected]                   :@@@Bu    [email protected]:   :@[email protected] [email protected]@[email protected]  :[email protected]   ,          .:iJZ5                  //
//                                   [email protected]@[email protected]  :L::.                [email protected]@O:  [email protected]   :[email protected]@[email protected]        [email protected]@U27:.FBPJu7i                     //
//                                               ,[email protected]@BU.  .:  :[email protected]@Bv,            [email protected]@7BBU  [email protected],                ,rJE. :[email protected],                        //
//                                               ,,      :GN:.:::..,   [email protected]            [email protected]@B   [email protected]                                                       //
//                                                       ,[email protected]     ..         iO5     .;[email protected]@[email protected] @MMB:                                                      //
//                                                    7k02;.        .iLv,       [email protected]@@BkL:.   [email protected]@[email protected]@2                                                      //
//                                                 rBB:     ...        ,u0i  .rUuFB8.             [email protected]@[email protected]                                                      //
//                                                  ,qB     .,rY5L,      :@B2ri.  r5                [email protected]                                                     //
//                                                 rr.           :JPY ,vv: @1     :M                 ,[email protected]                                                     //
//                                               rL    .,:iii.     iBB:    58     iM                  @[email protected]                                                     //
//                                              [email protected],        .r5k:ri  @     LN     7O                  [email protected]@L                                                    //
//                                                [email protected]        .:MM    M:    7U    :Ou                  ,[email protected]                                                    //
//                                              ;u:   .:,rrii. .0    N.    Y:   :@B,                   @@[email protected]                                                   //
//                                            iZ:       [email protected]   .5    u     Y    X 7                    [email protected]@                                                   //
//                                            BBr.   .:i  J    :;    i     : :,uu                       [email protected]                                                  //
//                                             :@P .i:   ,,    7    :       [email protected]@                        :@BOMBL                                                 //
//                                            PY  ,.     .    .:       Pr [email protected] r                          [email protected]                                                //
//                                          uB.           .         [email protected]                               @[email protected]                                                //
//                                         @@v.;ri:@i .::8B   .iF :0Z:[email protected]                                :@[email protected]@                                               //
//                                        iq7ii,  PBX5JiFBX7J7:@@Yj.  ,                                    [email protected]@O                                              //
//                                                :     7:.   :1.                                           [email protected]@E                                             //
//                                                                                                           [email protected]@0                                            //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RoseCheck is ERC721Creator {
    constructor() ERC721Creator("4ever Rose", "RoseCheck") {}
}