// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I AM SAD
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    @!              .:^^7?JYYJ????7!^:.      :^^.      .^       ^YBGJ~.      ..:~~!!77?~.  [email protected]@@@BPYJJJJJ    //
//    @7             ..:!~!~^^^^...         .?B&@@#J.    .G^     ^#@@@@@#G?^      .     .     [email protected]@@BJJJJJJJ    //
//    #:                                  ^Y#@@@@@@@Y     JY     [email protected]@@@@@@@@@BJ^.              ^&@@GJJJJJJJ    //
//    P                                .!P&@@@@@@@@@#.    ^B:    [email protected]@@@@@@@@@@@@#B5J!^.         P&BGJJJJJJJ    //
//    ~                             ^75#@@@@@@@@@@@@P      ?:     [email protected]@@@@@@@@@@@@@@@@@#PJ7^:.   7&YJJJJJJJJ    //
//                              :[email protected]@@@@@@@@@@@@@@B:             :[email protected]@@@@@@@@@@@@@@@@@@@&#GP5Y#5YYJJJJJJ    //
//                         :~?5B&@@@@@@@@@@@@@@@@@@^       ^~      [email protected] !5&@@@@@@@@@@@@@@@@@@@@@@@@@&##B5JJ    //
//                   .^!?5B&@@@@@@@@@@@@@@@@@@@#[email protected]: ..    !Y ~Y~  [email protected]^   :?G&@@@@@@@@@@@@@@@@@@@@@@@@@@#JJ    //
//            .:^~?YG#@@@@@@@@@@@@@@@@@@@@@@&G?. ~&!J&?    75 [email protected]!&#.      :7YG#&@@@@@@@@@@@@@@@@@@&#GYJJ    //
//      :!J5PGB&@@@@@@@@@@@@@@@@@@@@@@@@@#57^    ~&&@B.    7G   ?&@@B           .^~7Y5PGB####&[email protected]    //
//     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@&&BPY!^.       [email protected]@#:::   !#.   ^&@Y                 ..:^^::: [email protected]    //
//      .^!?J5PGBB##&&&&&##BBP5J7~^.         ..::[email protected]@PJBY   ~&:   [email protected]@7.                         [email protected]    //
//                ..:::::::..            .^~7JGB#&&BY~~B.  ^&^   [email protected]@&BG5YJ~^^^: . .            [email protected]~   ~5#GJ    //
//                               ..^!7JPB#&&&@B5?^.   :B^  :#^   PGJPGGBBB####BPY?7~~^::..:::[email protected]~     ~G&    //
//           ..::.^^~^^^^!7???Y5G#&B5PJ?7!^:[email protected]^       :B:  .B:   PB       [email protected]@@@@&#[email protected]^       7    //
//         ::~~!!7JPGBB#&#&@@@@@@@@&7       ~&:       ^B.  .B~   [email protected]^       :[email protected]@@@@@@&?JPB&&&##[email protected]~~~.        //
//        :7?Y5G#&@&#BBP7?&@@@@@@@@@&^      JB        ^&^   GJ   [email protected]       [email protected]@@@@@@@@7   :^7P#@@@J??7.        //
//       ^[email protected]#7^:.    [email protected]@@@@@@@@@@?     .BJ        ^&!   ?#.   B&:     :&@@@@@@@@@Y       :G&G~!!:         //
//       ....:7B#7       [email protected]@@@@@@@@@@G    .P#:        .#?   :&!   [email protected]     :&[email protected]@@@@@?      ^BB&Y^:           //
//     .!???7!~:J&Y      [email protected]&77&@@@@@@P.  ^BB^          G5    ~^    P&:     5#[email protected]@@@@5.     ?&GPG:~7^          //
//            .?~!&G!.   ~&@[email protected]@@@@@Y. .J#G7           GG          ^@G~    ^[email protected]@@@@#J     [email protected] YG        !G    //
//            .~?Y^~B&Y:  ^[email protected]@@@@&5^ :?#P5:~Y~         P#.          5#GG7:   :^~~^.    :7BG~  ?#.   :~JGBP    //
//           !YJ~  .P!P#557~7JJYJ~~?PB5P~:~ :~         [email protected]!          ^#57P#PJ!~^:::^~?5P5???   [email protected]?Y5GGPYJJ    //
//          .!:   .57 J?!PPBGPPBPB5775 :P:            ^[email protected]           P# .5Y5BYYBGY5&?7P^  :.  [email protected]    //
//                ~! ^P ?~?:?7.5.?7  P: ~^           :[email protected]           ^&~.7?^5.^YJ: 5! ~5.     G#JJJJJJJJJJ    //
//                   :: J:J 77 !.:Y. :.              ::[email protected]            PP  ~.5:^5?! ~Y  .     .B#JJJJJJJJJJ    //
//                  ^77!. . ..    .                  ..~#B            ^&~   ^..P^.  . .::     B#JJJJJJJJJJ    //
//                 [email protected]@@@B!                             .Y&:            YP      :.    !B&&BJ.  BBJJJJJJJJJJ    //
//                [email protected]@@@@@&^                             ^&!            .B~     ^!!~: [email protected]@@@@Y  GGJJJJJJJJJJ    //
//                ^#@@@@@@^                          [email protected]        .:. .JP   [email protected]@@@#~ [email protected]@@@5 .#PJJJJJJJJJJ    //
//                 :?PGP5~                           Y&Y~YG    .:..~!~^^~#:  [email protected]@@@@@@! ~55?. [email protected]    //
//    ^                                              !#?^[email protected]?.:^~!!~?77~!?#:  [email protected]@@@@@@G       [email protected]    //
//    5                     :^^:.                     ^[email protected]?JYJJ555Y5&?   :[email protected]@@@@@G      .#BJJJJJJJJJJJ    //
//    @7                 .?G&@@&#J.                      ..!P#&&&&#BB&&B7     :[email protected]@@@&!      [email protected]    //
//    &&~               [email protected]@@@@@@@Y                          .^!7?JJ?7~.        ^!77^       P&JJJJJJJJJJJJ    //
//    Y&&!              ^@@@@@@@@@#.                         ^:                            .#BJJJJJJJJJJJJ    //
//    JY&&~              [email protected]@@@@@@@5                          P~                            [email protected]    //
//    JJY&&~              ^?5GGPJ!                          ??                             G#JJJJJJJJJJJJJ    //
//    JJJ5&&!                                         ......:.                            Y&YJJJJJJJJJJJJJ    //
//    [email protected]@7                                  .^7JY555555555555J7^.                    [email protected]    //
//    Share Link                                                                                              //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SAD is ERC1155Creator {
    constructor() ERC1155Creator("I AM SAD", "SAD") {}
}