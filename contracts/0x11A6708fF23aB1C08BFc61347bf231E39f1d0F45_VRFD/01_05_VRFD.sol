// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARE YOU EVEN VERIFIED BRO?!
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    5Y^  :Y5P&@@5  .. !?.  [email protected]@@@@@@@@@@B~   .  :YB~  [email protected]@@@@@@#.   ~PP~    .#@@@&#BGP55PGB&@@@@@@@@@@@@@    //
//    @@@##@@@@@@@J  :?J7.   [email protected]@@@@@@@@@@5   ^GYJBJ:    ^@@@@@@&@G:         :P&PJ~:.       ..^[email protected]@@@@@@@@    //
//    @&G5YY5G&@@@@7.  .   [email protected]@&&@@@@@@@@@P.  .?Y:     7&@@B77^.!JJ57^...^75P7.                  ^J#@@@@@@    //
//    7:      .7#@@@&G7YJ~?J?!^:::[email protected]@@@@@?.         :[email protected]#!:       [email protected]&&&@G~                       .?&@@@@    //
//           75::[email protected]@&#BG7:           7BBGGB&#BB?^:~PBB&@@P  .^.7J.  [email protected]@@@J                           :[email protected]@@    //
//     ~?. !B#?: ?P!:                      [email protected]@@@@@@@@@@G^  7J!    [email protected]@@7                    ^!^       [email protected]@    //
//     ~GBBB?.   .                            ^Y?7!7JG&@@@P~^    :^[email protected]@@5         .         [email protected]@@^      :&@    //
//    :  ~7.   ^!                                     :[email protected]@@@&5GG777!~~!:       :G#G!     [email protected]@@G!        [email protected]    //
//    #5?~^[email protected]                    :~         .  .JB! [email protected]@@@@P^.              [email protected]@@[email protected]@@P~          [email protected]    //
//    @@@@@@@@&5~                  .J&@B!        .?#G!. [email protected]@@@?                   ^Y&@@&@@&5^            [email protected]    //
//    @@@@@@@P:                  .?#@@&Y:        .J!    [email protected]@@B        .?!           :J#@&Y:             .#@    //
//    @@@@@@#.         :JJ:    .?#@@&Y:              [email protected]@@@B    JJ^J57.             .^.               [email protected]@    //
//    @@@@@@#.        ^[email protected]@&Y:.7#@@&5:              [email protected]@@@@@@?   .75!                                [email protected]@@    //
//    @@@@@@@5         :?#@@&#@@@5^               [email protected]@@@@@@@@@@5^         .!^                        !#@@@@    //
//    @@@@@@@@B?:        [email protected]@@P^              [email protected]@@@@@@@&BBB#B7     :[email protected]&5~.                  :[email protected]@@@@@    //
//    @@@@@@@@@@P           75^                [email protected]@@@@@@@@@7           .^^::[email protected]@#57^.          :~?P&@@@@@@@@    //
//    @@@@@&GJ!~:                              [email protected]@@@@@@@&G.                 [email protected]@@@@#BPP555YJ5#@@@@@@@@@@@@@    //
//    @@@@P:                                  :[email protected]@@@@5!^:                   .!YG&@@@@#PP?:[email protected]@@@@@@@@@    //
//    @@@P   ^.  !?.                       .:?#@@@@@@5                .         [email protected]@@5           [email protected]@@@@@@@@    //
//    @@@7   JGJPP~   :5PG!                !&@@@@@@@@G              .7B5:      .#@@G^      :YJ  [email protected]@@@@@@@    //
//    @@@B.   :?^     [email protected]@@@G7^.        :!. [email protected]@@@@@@&~       ..   [email protected]~       [email protected]&.   JJ^JBJ:    [email protected]@@@@@@    //
//    BY5&G!.       [email protected]@@@@@@@~   ^^ .YBJ    [email protected]@@@@@7       :P#[email protected]!           [email protected]:  :JBJ.    .Y&@@P5Y~?    //
//       [email protected]@@@@@@@@@J.  !GGBJ.    :[email protected]@@&&PPP!      :?G&@B7.           [email protected]@Y           [email protected]@P?         //
//      :~  :#@@@@@@@@@@@@@@@@@5    !:      #@&#!..  ^^.        ~7.           [email protected]@@@@GYY7.  ~YYP&@@~  . .7    //
//    7?J^   [email protected]@@@@@@@@@@@@@@&#G^       ^^[email protected]@J     .^                        [email protected]@@@@@@@@@&##@@@@@@#~  !JY!    //
//    ^^    7&@@@@@@@@@@@#5?~:......   .~?G&@@~  ^!7Y~   :!~              ..:^[email protected]@@@@@@@@#G555P#@@@@#:. .      //
//    :~~^??5BB#&@@@@@&5!.          ....   :7GB. .~!    !&@@G~   .~^.   !B&&@@@&&&&&@@P~.      ^[email protected]@@&#J7Y?    //
//    @&J^:.   .:!5&@Y^      ...........      ~?5~ :::7?P&#&@@P5B&@@#GJ5#GY7~^::::::^~     . :J? [email protected]@@@@@5~    //
//    Y.           ^~    ...............  ..   .J&&&5~^:...:^[email protected]@@@@@G?^.                   ^BG!  [email protected]@@#~      //
//             ^J:    ................  .!GG!.   7P^           [email protected]#?:                        :   :&@@@!       //
//       .~  ^YY~     ....    ......   [email protected]@@@J.            .7:  :?.                             [email protected]@@@^       //
//       :Y5YY^       ..   .    ..   [email protected]@@@G!....    .:  :?5!.                                   ^[email protected]@@Y       //
//    ?    ^^        .. .:?BY^     [email protected]@@@P~    ..    :5YJ5!                                        [email protected]@@5:     //
//    @B?:      .^. ..  :[email protected]@@&5^ [email protected]@@@P~   . .....    ~!                               ~Y~        .#@@@&5    //
//    @@@@#GP5PG#@! .... [email protected]@@&[email protected]@@@P~    ....   YG!.      .                         [email protected]@5.        [email protected]@@@@    //
//    @@@@@@@@@@@@#^       [email protected]@@@@P~   .......  [email protected]@@#G5YY?!~                       [email protected]@5^          .&@@@@    //
//    @@@@@@@@@@@@&?         .!G&5~          .  7&@@@@@@&?:             ::        [email protected]@5^            .&@@@@    //
//    #@@@@@@@@@@P:            .:             ^[email protected]@@@@@@&^  :.          [email protected]@5^   .?#@@5:              :&@@@@    //
//     [email protected]@@@@@@@#.  ~7..^.                    [email protected]@@@@@@@B   !G!         :J#@@5~?#@&Y:                [email protected]@@@@    //
//     [email protected]@@@@@@B   ^5GGY.    .      .  ~7~.   [email protected]@@@@@@@~   .~           .?#@@@&J:                  J&&@@@    //
//      :@@@@@@@@J    ::     ?BG5^   !PG5^    [email protected]@@&&G5##7.                .7GJ.                     ..:[email protected]    //
//     ^[email protected]@&5P?!5GY7:     [email protected]@@@&.   :^      [email protected]@#Y..  .:!BPJ777^                                   ~!  :#    //
//     [email protected]&5!      .5BBGPPB&@@@@@@@P!^^    :^~?&@B.     ^. [email protected]@@@&J.                            :^ ^PG!   .    //
//    [email protected]@G     ^?.  [email protected]@@@@@@@@@@@@@@@@GYJ5&@@@@@Y  .7!J7.  [email protected]@@@@@#J^                          !GGG7     ^    //
//    @@@5. .?JJ^   !&@@@@@@@@@@@@@@@@@@&&&@@@@@&7  :!.   [email protected]@@@@@@@@G?^.                .^J!    ~.     ^&    //
//    @@@@Y.  .   .~&@@@@@@@@@@@@@@@B?~:..:^[email protected]@@#5J.:^.!?J#B#&@@@@@@@@@#GY?!~^^^^^^~!?YG#@@#?^^.   .^^[email protected]    //
//    ?#@@@&G!7?~?YJYY5B&@@@@@@@@@@J.       : !&@@@@&@B7~:.  .:!5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@    //
//    Share Link                                                                                              //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VRFD is ERC1155Creator {
    constructor() ERC1155Creator("ARE YOU EVEN VERIFIED BRO?!", "VRFD") {}
}