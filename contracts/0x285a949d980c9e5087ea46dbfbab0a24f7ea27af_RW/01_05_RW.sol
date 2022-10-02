// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Landscape Photography By Ryan Warner
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                   .^                                                     //
//                                                  ^!:                                                     //
//                                                 :!!!.                                                    //
//                                                :!!!!~                                                    //
//                                               :!!!!!!~                                                   //
//                                              :!!!!!!!!~.                                                 //
//                                            .~!!!!!!!!!!~.                                                //
//                                           ^!!!!!!!!!!!!!!^.                                              //
//                                         :~~^~!!!!!!7!!77!!~:                                             //
//                                         :^!77777777??7???7!^.                                            //
//                                      .^!7???????????????????7~:                                          //
//                                   :~!7!77!7????????????????7???!:                                        //
//                                   :^:  .:!??????????????????7!^^!~.                                      //
//                                      .^!?JJ???JJJJJJJJ??JJJJJ7^.                                         //
//                                ..:^!7?JJJJJJJJJJJJJJJJJJJJJJJJJ?!:                                       //
//                                ^????JJJJJJJJJJJJJJJJJJJJJJJJJJJJJ7!^                                     //
//                                 ..^7JJJJJJJJJJJJ?JJJJJJYYJJJJYJJ?^:.                                     //
//                                  .~JJJJJJJJYJJJJJJJYJYYYYYYYYYYYYY?7~:                                   //
//                               .^7JYYYYYYJYYYYYYJJYYYYYYYYYYYYYYYYYYYYYJ7!^.                              //
//                           .~7JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?7!.                              //
//                            :~!!!??7JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY!                                  //
//                            .^7Y5P55555555555Y55PPP555P555P55555555PPPPP5Y?!^:.                           //
//                        .^7J5PPPPP555555555555PPPPPPPPPPPPPP55555555PPPP5YJJYYYJ7~.                       //
//                    :!?Y5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5PPPPP5555PPPPPGP5Y?~^^^.                       //
//                     ~777!7PPPPPPPPPGGPPPPPPPPPPPPPPPGGPPPPPPPPPPPPPPPPPPPPGGGY~.                         //
//                 ...:^~7J5PGGGGGGGGGGGGGGGGGGPPPPPPGGGGGPPPGPPPPPPPPPPPPPPPGGGGGG5~                       //
//                :5PPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPGGPPPPPGGGGGP7~:                        //
//                 ^JGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG5J7!~~^                   //
//             .:~75GGGGGGGGGGGPGGGGGGGGGG5J?YGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBG~                   //
//            .?PGGGP5J!^!??7~::~PGGGGGPY!   JGGGGBGGGGGGGGPPGGGGGGGGGGGGGGGGGGG555YYJ!:                    //
//              :^^:.           .5P5J7~.     .!BB##GGGGBBBB!:PGGGGGGGGGGGGGGGPP5:                           //
//                                .           ^####BBBB####~ :YGGGGGP5GGGGGGGY^.                            //
//                                            ^###B#####BBB~   ~YGGGG!:?5GGGGBJ                             //
//                                            ^#######BBBB#~     :^~^   .^7?J?:                             //
//                                            ^############~                                                //
//                                            :5PPPGGGGPPP5:                                                //
//                                                                                                          //
//                                                                                                          //
//        ________      ______      __      _   ___       ___ ____  ______     __      _ ___________        //
//       (   __ ) \    / (    )    /  \    / ) (  (       )  |    )(   __ \   /  \    / ) ___(   __ \       //
//        ) (__) ) \  / // /\ \   / /\ \  / /   \  \  _  /  // /\ \ ) (__) ) / /\ \  / ( (__  ) (__) )      //
//       (    __/ \ \/ /( (__) )  ) ) ) ) ) )    \  \/ \/  /( (__) |    __/  ) ) ) ) ) )) __)(    __/       //
//        ) \ \  _ \  /  )    (  ( ( ( ( ( (      )   _   (  )    ( ) \ \  _( ( ( ( ( (( (    ) \ \  _      //
//       ( ( \ \_)) )(  /  /\  \ / /  \ \/ /      \  ( )  / /  /\  ( ( \ \_)) /  \ \/ / \ \__( ( \ \_))     //
//        )_) \__/ /__\/__(  )__(_/    \__/        \_/ \_/ /__(  )__)_) \__(_/    \__/   \____)_) \__/      //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RW is ERC721Creator {
    constructor() ERC721Creator("Landscape Photography By Ryan Warner", "RW") {}
}