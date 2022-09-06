// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 5K Remixes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                              ..^!?Y5GB##&&&&&&&&&&&&&##BG5Y?!^..                                               //
//                                       .:!JPB&&@@@@@&&&##BBGGGGGPGGGGBB##&&@@@@@&&BPJ!:.                                        //
//                                   :7P#&@@@@&#BP5J?77!!~~~~~~~~~~~~~~~~~~!!77?Y5G#&&@@@&#P7:                                    //
//                               ^JB&@@@&#B5J7!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!?YP#&@@@&BJ^                                //
//                           .7G&@@@&#PJ7~~~7JYYYYYYYYYYYJJYYYYYYYYYYYYYJJYYYYYYYYYYYY7~^~!?YG&@@@&G7.                            //
//                         !G&@@@&GJ7~~~~!Y&&[email protected][email protected]?????7Y&&5!~~~~!?5#&@@&G!                          //
//                      :5&@@@&G?!~~~~~7G&&?  5! [email protected]            [email protected]????JJJJ?J?  !B&B?~~~~~~75#@@@&5:                       //
//                    :[email protected]@@@#Y!~~~~~!Y#@B^    .         :@Y            [email protected]               :5&#Y!~~~~~~?G&@@@G:                     //
//                  [email protected]@@@[email protected]@^ PG             :@Y           ~:@J              ?#. &@&!~~~~~~~7P&@@@P.                   //
//                 ?&@@@#J~~~~~~~~~~#@@. &&     :J5J^   :@5            :@Y    .?YY~     [email protected]: &@@[email protected]@@&?                  //
//                [email protected]@@&P!~~~~~~~~~~~#@@. &&    [email protected]@@@@^  :@5            :@5   [email protected]@@@@?    [email protected]: &@@7~~~~~~~~~~~Y&@@@G                 //
//              .#@@@&J~~~~~~~~~~~~~#@@. &&    :@@@@@~  :@Y            [email protected]   [email protected]@@@@Y    [email protected]^ &@@7~~~~~~~~~~~~7#@@@#.               //
//              [email protected]@@&[email protected]@. &&    :@@@@@!  :@Y            [email protected]   [email protected]@@@@J    [email protected]^ &@@!~~~~~~~~~~~~~7&@@@B               //
//             [email protected]@@&[email protected]@. @&    :@@@@@!  :@Y            [email protected]   [email protected]@@@@J    [email protected]^ &@@!~~~~~~~~~~~~~~?&@@@5              //
//            [email protected]@@@[email protected]@. @#    [email protected]@@@@!  :@B?&?^^^^^^^[email protected]   [email protected]@@@@?    [email protected]~ &@@[email protected]@@@.             //
//            [email protected]@@&[email protected]@. @#    [email protected]@@@@~   :~^^^~~~~~~~^^~~.   [email protected]@@@@?    [email protected]^ &@@!~~~~~~~~~~~~~~~7&@@@J             //
//            [email protected]@@&[email protected]@. @#   :[email protected]@@@@B7:                   [email protected]@@@@B^   [email protected]~ &@&!~~~~~~~~~~~~~~~!&@@@G             //
//            [email protected]@@&[email protected]@:[email protected]# !&@&GPYJYG#&&~               :[email protected]&B5JJYP#@@Y [email protected]! @@@7!!~~~~~~~~~~~~~!&@@@G             //
//            [email protected]@@&7~~~~~~~~~~~!#&&PPBBYYG7^@@B?7.   :??&@&&&&&&&&&&&&&&&@@G?!    [email protected]@5^B5YGBG5#&&P~~~~~~~~~~~7&@@@Y             //
//            :@@@@[email protected]@@[email protected]@&5J~:.:[email protected]#[email protected]&5?^..:[email protected]@#?JJYJJJJ&@@#[email protected]@@@:             //
//             [email protected]@@&[email protected]@&.     J&J:?#&&######G!              YY:~5######&&&5: .       [email protected]@#~~~~~~~~~~7&@@@P              //
//              #@@@#[email protected]@&        !Y~ :@@@@@J                   ^!!.^@@@@@Y            [email protected]@#~~~~~~~~~!#@@@#               //
//              .&@@@#[email protected]@&:??:         [email protected]@@#.   :J??????????????^    [email protected]@@&:            [email protected]@&~~~~~~~~!#@@@&.               //
//               [email protected]@@&?~~~~~~~!B&@@#GPPJ^:::::  ...   .#BYYYYY55555555Y?P&!    ..           ~P&@@&5~~~~~~~?&@@@B.                //
//                 [email protected]@@&G!~~~~~~~!?P&@@&#######J       [email protected][email protected]@@&#BBBGGBB&@:@B       ^[email protected]@@#57~~~~~~~!G&@@@Y                  //
//                  :[email protected]@@&5!~~~~~~~~~!YB###B&@@#       [email protected]!&@@@#[email protected][email protected]       [email protected]@@&&&&&GJ!~~~~~~~~!5&@@@B:                   //
//                    [email protected]@@&P7~~~~~~~~~~~~~^[email protected]@#       [email protected]!&@@@&[email protected][email protected]       [email protected]@J~~~~~~~~~~~~~~7P&@@@B~                     //
//                      ^G&@@&[email protected]@#       [email protected]!&@###&&&&&###&@[email protected]       [email protected]@Y~~~~~~~~~~~!YB&@@&G^                       //
//                        .J#@@@&[email protected]@@PPPPPP5#@[email protected]&~~~~~~~~~~^[email protected]@&555555Y&@@Y~~~~~~~~7YB&@@@#J.                         //
//                           :[email protected]@@&#PJ7~~~~7GBB#######BBBB5~~~~~~~~~~~7BBBB#######BBG7~~~~7JP#&@@@BJ:                            //
//                              .!P#@@@&#G5J7~~^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^~~7J5G#&@@@#P!.                               //
//                                  .~YB&@@@@&#G5Y?7!!~~~~~~~~~~~~~~~~~~~~~~~!!7?Y5G#&@@@@&BY~.                                   //
//                                       .~?5B&&@@@@&&&#BBGPP555555555PPGBB#&&&@@@@&&B5?~.                                        //
//                                             ..^!?YPG##&&&&@@@@@@@@@&&&&#BGPY?!^..                                              //
//                                                          ...........                                                           //
//                                                                                                                                //
//                                                                                                                                //
//                               .&&BG#&?   ?&#BBG.  .&#   .#&.   B&.  .##  G&^   G&BBB5   7&#GG&#                                //
//                               [email protected]&  [email protected]   [email protected]      :@@Y  [email protected]@.   &@.   [email protected]@5    #@:      [email protected]  &@.                               //
//                               [email protected]&  [email protected]   [email protected]::.   :@@@.^@@@.   &@.    [email protected]@B     #@!::    ^&&J.                                  //
//                               [email protected]&[email protected]&Y:   [email protected]#5P!   :@B##&##@.   &@.    ^@@J     #@G55.     ^#&5.                                //
//                               [email protected]& [email protected]~    [email protected]      :@G^@@^[email protected]   &@.   .&#[email protected]^    #@.      ~5: :@@.                               //
//                               [email protected]&  &@:   [email protected]~!~   :@B GP #@.   &@.   #@: &@.   &@J~!^   [email protected]^[email protected]@.                               //
//                                J7  .Y!   ^JJJJJ   .J!    7J    7J   :Y!  ^Y~   7JJJY7   .JJJJJ7                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract P5KR is ERC721Creator {
    constructor() ERC721Creator("5K Remixes", "P5KR") {}
}