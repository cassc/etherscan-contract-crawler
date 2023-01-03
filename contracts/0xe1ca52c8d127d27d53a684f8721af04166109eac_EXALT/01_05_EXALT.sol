// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ExaltedNFTs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG7.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.?GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     ~GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                    ..............   ......      ......       .......        ......       ................    ..............     .........                           !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                   .GGGGGGGGGGGGG5   ~GGGGG?    7GGGGP.      JGGGGGG5        JGGGGP      7BGGGGGGGGGGGGGGB7  .PGGGGGGGGGGGGY    !GGGGGGGGGP5J~.                      !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                   .GGGGGPPPPPPPPJ    ^GGGGG7  ~GGGG5.      ~GGGPGGGG7       JGGGGP      !PPPPPGGGGGGPPPPP!  .PGGGGGPPPPPPPJ    !GGGGG55PGBGGBGJ.                    !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                   .GGGGG7             :PGGGG!:GGGGY.      .PGGG~!GGGG^      JGGGGP            YGGGGY        .PGGGG7            !GGGGG.  .~PGGGGP.                   !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                   .GGGGGJ^^^^^^.       .5GGGGGGGGJ        JGGGP. PGGG5      JGGGGP            YGGGGJ        .PGGGGJ^^^^^^.     !GGGGG.    :GGGGG?                   !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                   .GGGGGGBBBBBBJ        .PGGGGGGJ        ~GGGG!  !GGGG7     JGGGGP            YGGGGJ        .PGGGGGBBBBBB7     !GGGGG.     5GGGG5                   !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                   .GGGGGPYYYYYY!        7GGGGGGGP:      .PGGGG~::~GGGGG:    JGGGGP            YGGGGJ        .PGGGGPYYYYYY~     !GGGGG.     PGGGGY                   !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                   .GGGGG!              JGGGG?PGGGG^     JGGGGGBBBBGGGGG5    JGGGGP            YGGGGJ        .PGGGG!            !GGGGG.    !GGGGB!                   !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                   .GGGGG?::::::::     YGGGG! ^GGGGG!   ^GGGGPJJJJJJPGGGG7   JGGGGP^:::::::    YGGGGJ        .PGGGGJ::::::::    !GGGGG^.:!5GGGGG?                    !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                   .GGGGGGBBBBBBBG.  .5BGGB?   ^GGGGB? .PGGGB!      !BGGGG:  JBGGGGBBBBBBBG:   YBGGBY        .GGGGGGBBBBBBBG.   !BGGGGGBBBBBGGY^                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                    Y555555555555Y. .J5555?     ^55555775555Y.       Y5555?  75555555555555.   ?55557        .Y555555555555Y    ~5555555YY?!^.                       !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     :J???????J~          ?????????        ~J?????????????????????7   .J??????????????????????????J^         :~?Y5PPPPP5Y?!:.                        !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~BGGGGGGGGG7        .GGGGGGGBG        ?BGGGGGGGGGGGGGGGGGGGGB5   ^BGGGGGGGGGGGGGGGGGGGGGGGGGGB7      ^JPGBGGGGGGGGGGGBGG57.                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGGGGG7       .GGGGGGGGP        ?GGGGGGGGGGGGGGGGGGGGGG5   ^GGGGGGGGGGGGGGGGGGGGGGGGGGGB7    :5GGGGGGGGGGGGGGGGGGGGBY.                    !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGGGGGG?      .GGGGGGGGP        ?GGGGGGGGGPPPPPPPPPPPPPY   :PPPPPPPPPGGGGGGGGGGPPPPPPPPP!   ^GGGGGGGGGG5YYY5PGGGGGP~                      !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGGGGGGGJ     .GGGGGGGGP        ?GGGGGGGG5                           JGGGGGGGG5             5GGGGGGGGY.      .^757                        !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGPGGGGGGY     PGGGGGGGP        ?GGGGGGGGY                           ?GGGGGGGG5             PGGGGGGGG5:                                   !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGG7?GGGGGGY    5GGGGGGGP        ?GGGGGGGGY                           ?GGGGGGGG5             ?BGGGGGGGGGPY7^.                              !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGY JGGGGGG5.  YGGGGGGGP        ?GGGGGGGGPJJJJJJJJJJJ7               ?GGGGGGGG5              JGGGGGGGGGGGGGGPY?!:                         !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGP  YGGGGGG5  7GGGGGGGP        ?GGGGGGGGGGGGGGGGGGGBP               ?GGGGGGGG5               ^YGBGGGGGGGGGGGGGBGPJ^                      !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGG:  YGGGGGGY ^GGGGGGGP        ?GGGGGGGGGGGGGGGGGGGGP               ?GGGGGGGG5                 .!JPGGGGGGGGGGGGGGGG5.                    !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGG~   YGGGGGGJ:PGGGGGGP        ?GGGGGGGGGPPPPPPPPPPPY               ?GGGGGGGG5                     .^7J5GGGGGGGGGGGGP.                   !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGG!    JGGGGGGYPGGGGGGP        ?GGGGGGGG5                           ?GGGGGGGG5                          .^75GGGGGGGGG!                   !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGG7     ?GGGGGGGGGGGGGP        ?GGGGGGGGY                           ?GGGGGGGG5                7J~.         :GGGGGGGGG7                   !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGG7      ?GGGGGGGGGGGGP        ?GGGGGGGGY                           ?GGGGGGGG5              ~PGGGG5?!^::::!5GGGGGGGGG:                   !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGG7       7GGGGGGGGGGGP        ?GGGGGGGGY                           ?GGGGGGGG5            ^5BGGGGGGGBGGGGGGGGGGGGGGP^                    !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~GGGGGGGG7        !GGGGGGGGGGP        ?GGGGGGGGY                           ?GGGGGGGG5            ~YGGGGGGGGGGGGGGGGGGGGGP?.                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                     ~BGGGGGGB7         !GGGGGGGGGP        ?BGGGGGGGY                           JBGGGGGGG5              .^7YPGGGGBBBBBGGGG5?^                        !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                      :......:.          ..........        .:........                           ..........                   .:^^~!!!~~^:.                           !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     !GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG^                                                                                                                                                                     ~GGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGG?~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~JGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EXALT is ERC1155Creator {
    constructor() ERC1155Creator("ExaltedNFTs", "EXALT") {}
}