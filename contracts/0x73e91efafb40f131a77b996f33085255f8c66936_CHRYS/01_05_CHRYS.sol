// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Courtney Kinnare
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                     :7J!:.                  :!?Y5555J?7~^^^^~7JJ.  ^Y^                               //
//                                  .~Y#@@@#GY?~^:..         ^5#@@@@@@@@@@@&&###&#~  ~G7                                //
//                         :^.    :7G&@@@@@@@@@&&#BGP5Y~    7#@@@&&&@@@@@&&BP5P##~  ^BJ                                 //
//                     .^?5J^. .~YB#P#@&&@@@@@@@@@@@&P~.   ~#B57!~~~~!!7!~^!5#@@?  .PP.        ^7^                      //
//                   .7P#P~  :7G&&Y^.P&!~7YPB#&@@@&P~.     J7:           :J#@@@G.  7#~      .~Y#@#J:                    //
//                 [email protected]#?..~Y#@@@#^  P&^    .:~?Y5!.       .            :[email protected]@@@@?  .PG.    :7P&@@@@@B?:                  //
//                :5&@#!  ?&@@@@@#:  P&^                               [email protected]@@@@&~  :#J  .~JP#@@@@@@@@@B7.                //
//               [email protected]@&!   [email protected]@@@@@#:  P&^                               ~&@@@@@&^  ^&7^?557:^Y#@@@@@@@@&Y.               //
//              ^[email protected]@@Y    [email protected]@@@@@#:  P&^                       .:~!!!~^[email protected]@@@@@&^  ~&G5?^.    ^5&@@@&BY~.                //
//             [email protected]@@&^    [email protected]@@@@@#:  P&^                      ~P#&@@@&#&@@@@@@&^  ~&?.        .J&#5!:                   //
//             [email protected]@@@B.    [email protected]@@@@@#:  P&^                     ^YY??JYG&@@@@@@@@&^  ~&!       :?PP?:                      //
//            [email protected]@@@G.    [email protected]@@@@@#:  P&^                            .^[email protected]@@@@@@&^  ~&!    .!5GY~.                        //
//            ^&@@@@#:    [email protected]@@@@@B.  P&^                              [email protected]@@@@@&^  ~&!  ^?G&@G?^                         //
//            ~&@@@@@7    [email protected]@@@@@?   P&^                               ^&@@@@@&^  ~&?!5#@@@@@@#P!.                      //
//            ^&@@@@@B^   [email protected]@@@&Y.   P&^                        ~J5P5Y?7#@@@@@&^  ~&BB#&@@@@@@@@&G7.                    //
//            [email protected]@@@@@P:  [email protected]@@B7.    P&^                       7GGG#@@@@@@@@@@P.  7#~.:^!5#@@@@@@@&P^                   //
//             [email protected]@@@@@@G~:[email protected]?:      P&^                       ::..:?&@@@@@@@B^  .PY      :?#@@@@@@@#7                  //
//             :[email protected]@@@@@@#G#7:        P&^                ..          [email protected]@@@@@P^  .J5.        ^[email protected]@@@@@@&J.                //
//              ^[email protected]@@@@@@@&5~.       P&^             .~JY:          [email protected]@@&G7.  ^YJ.          .?&@@@@@@@P^               //
//               ^[email protected]@@@@@@@@&GJ~:.   P&^          .^?G#5:           7&@&P!..^75G?~^^::..     .?#&@@@@@@@B!  ::          //
//                :J#@@@@@@@@@@&#PY?!G&!::...:^~?5B&@B7.          :J#BJ~^7YB&@@@&&&&##[email protected]@@@@@@&YYG7          //
//                  ^JB&@@@@@@@@@@@@@@@&#BBBB#&@@@&G?:          :?B#Y?YG&@@@@@@@@@@@@@@@@@@&G7.  :[email protected]@@@@@@#Y^           //
//                    :!YB&@@@@@@@@@@@@@@@@@@@@&BY!.          :[email protected]@@&&&##BBBBBB#&&@@@@@@@@#J:     .?#@@@&5^             //
//                       .^!J5GB##&&&&&&&##BPY7~.            !G#BP5J7~^::.....::^~!?5GB&#Y:         ^5#5~               //
//                            ..::^^^~^^^::.                 .^:..                   .:^^            .:.                //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                  .                                                                                                   //
//              :!!^:^7J: .?P^                                      :J5:  ~J:                                           //
//            .JG7.   :5^ .PP.                                      :BJ   :~.                                           //
//           :P#!      .. !#!:^~.  .^~.:~~.^~:  ~:  ::~^   .^::^^   JB: .:~.  .::~: .^~.:^~..:~^                        //
//           [email protected]         .GP~:!#! ^:7#7^~?!!PP. 5? ?5:~7..?J^.~BJ  ^#7 ::!#! .5?.7!^:?B~^^BJ^:JB:       ..              //
//          [email protected]?       . ?#! .YB: ..5B^   ^ ~&! ?: 7BY: :PP: .YG:  5G. ..GP. .YB7. ..GG: !&7 :BY        ?^              //
//           [email protected]    .~::BJ  7#!.. 7#!      :#?~^.: ^PP.J#^ .7#!.:~#! . J#^.:..!B?  ?#~ :G5..5G:..     .G7              //
//           .?GY!^^^^. 7P:  YP^^..PJ       .BY^ ^5~:?7 ?G!^^?G~^.?P^^..PY^^?J^^J^ :P?  7G: :G?^^      ~&P.             //
//             .::::.   ..   .:.   ..       ~J:   ....   ::. .:.  .:.   .:.  ...    .   ..   ::.      [email protected]&!             //
//                                      !?7~:                                                     .:^[email protected]#&#Y~^..        //
//                                      ^~:                                                      .~7YB&@[email protected]#PJ!^.       //
//          .YPPPP!    ~PPPPY.   .YPPPP!    ~PPPPY.   .YPPPP!    ~PPPPY.   .YPPPP!    ~PPPPY.        .7#@@P^.           //
//          [email protected]@@@?    [email protected]@@@B:   [email protected]@@@?    [email protected]@@@B:   [email protected]@@@?    [email protected]@@@B.   [email protected]@@@?    [email protected]@@@B.          [email protected]:             //
//          .YGGGPJ~~~~?PGGG5!~~~!5GGGP?~~~~?PGGG5!~~~!5GGGGJ~~~~?PGGG5!~~~!5GGGPJ~~~~?PGGG5!~~~~.     :#J              //
//            ....Y&&&&5....^#&&&&~....Y&&&&5....^#&&&&~....Y&&&&P....^#&&&&~....Y&&&&P....^#&&&&~      5~              //
//                J####Y    :G###B^    J####Y    :G###B^    J####Y    :G###B^    J####Y    :G###B^      ~:              //
//                .::::.     :::::     .::::.     :::::     .::::.     :::::     .::::.     :::::                       //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CHRYS is ERC721Creator {
    constructor() ERC721Creator("Courtney Kinnare", "CHRYS") {}
}