// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Choose Your Adventure
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                   //
//                                                                                                                                                   //
//                    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:                                            .^!!~:                                    //
//                     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:              5Y                           P5Y5BG&#GB#G7^                             //
//                      ^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:             [email protected]&      .^.        .?Y7.    G&5#&&&&&@@&J!J#.                           //
//                     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:             [email protected]@~     &@@Y?JJJY55&@@@@G  .&PB5B&#G#@&5?PG&.                           //
//                     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:              [email protected]&.    !7^ .....:^^^[email protected]&@#?7&@#&&[email protected]@@&&&&G^                            //
//                     [email protected]?&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:               [email protected]&                  :&@B55#G#&&@&&@&&#PPB                             //
//                     &@5^^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:                [email protected]           .:^7JJB&###&GB#?&[email protected]~                           //
//                     @@? . &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:      ?:         ?&B::~^~7JJ5#GBBBP#YPGB&&&&JPB##YJGPPPP5B?Y                          //
//               .:..  &@. ~  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:      [email protected]         7#&@&@@@#J5#&P##PG&#PYP&@@~PB5#~!#B&BGJBPJ~                         //
//              [email protected]@@@#[email protected]&  !   .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:       [email protected]&7.       &B#&B#55??!!~^::JBYPGY!7!!!5G?:#GGBGYJG&?B                         //
//              @@@@@@@@P  ^.   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@:         [email protected]@G~      [email protected]#         757Y5~.!JB5.:!7J##!##GGB#@J                         //
//              .7&@@@@@@5 .^   :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:           7G&&5~.   ^[email protected]^      JP57.   [email protected]~!B7:PJ&#5B#&#B&J                         //
//                [email protected]@@@@@@&.^    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@:             .75GPJ~. :[email protected]&#!.  5#Y:    ..5? JY GJ^[email protected]#BJ?##&                          //
//               [email protected]@@@@@@@@B!     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@:                [email protected]&&BGGBP.  ..:!JG^.!.~P .:@&&&[email protected]?                          //
//               #@&[email protected]@@@@@@J      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@:                   .!5G&@#[email protected]&B:.!J7..:7?.  !Y^[email protected]&B##&5                           //
//              [email protected]@B [email protected]@@@@@#7       [email protected]@@@@@@@@@@@@@@@@@@@@@@:                      .7G&#[email protected]&P.~57 ~Y^      ?J^.!?P7###G~                            //
//               :#@#:#@@@@@@?         .GBG5JJ#@@@@@@@@@@@@@@@:                         [email protected]@&5!JB&B!       .~77?YJ5P^                              //
//                 :#@@@@@@@@~                 ~B&@@@@@@@@@@@@:                           :GB&&@@@@&!.            ..                                 //
//                  [email protected]@@@@@@@!                     :!5#@@@@@@@:                            :GGP##B5B.                                                //
//                  .P&@@@@@@&                          [email protected]@@@@:                             :GB? 7PPP?:                                              //
//                    [email protected]@@@@@@J                          [email protected]@@@:                              .PG~  :?PB5!.                                           //
//                     :^[email protected]@@&                           &@@@:                               .G#7    ~YG#P!.                                        //
//                     !&@@@@@~                           [email protected]@@:                                .G#:     .7G&@#?:                                     //
//                   [email protected]#7#@@7                             .P&:                                 :##.       :J#&@&BY.                                 //
//                  7#@#.  [email protected]@:                                                                   ^&#.         .~?55.                                //
//                  [email protected]&    [email protected]&                                                                     ^@&:                                              //
//                 :&~    [email protected]@.                                                                     ^@&~                                              //
//                       [email protected]@@.                                                                     :[email protected]#7                                             //
//                       [email protected]&.                                                                        .?G^                                            //
//                                                                                                                                                   //
//                                                                                                                                                   //
//                  ___ _                                                    _       _                 _                                             //
//                 / __\ |__   ___   ___  ___  ___  /\_/\___  _   _ _ __    /_\   __| |_   _____ _ __ | |_ _   _ _ __ ___                            //
//                / /  | '_ \ / _ \ / _ \/ __|/ _ \ \_ _/ _ \| | | | '__|  //_\\ / _` \ \ / / _ \ '_ \| __| | | | '__/ _ \                           //
//               / /___| | | | (_) | (_) \__ \  __/  / \ (_) | |_| | |    /  _  \ (_| |\ V /  __/ | | | |_| |_| | | |  __/                           //
//               \____/|_| |_|\___/ \___/|___/\___|  \_/\___/ \__,_|_|    \_/ \_/\__,_| \_/ \___|_| |_|\__|\__,_|_|  \___|                           //
//                                                                                                                                                   //
//                                                                                                                                                   //
//                                                                                                                                                   //
//                                                                                                                                                   //
//                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CYA is ERC721Creator {
    constructor() ERC721Creator("Choose Your Adventure", "CYA") {}
}