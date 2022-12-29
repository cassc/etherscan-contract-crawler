// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pizza Pairatsu
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                       ..................                                                   //
//                        ..:^^~!77???JJJJYYYYYYYYYYYYYYYYYYYYJJJ???77!~~~^^:..                               //
//               .:~!7??JJJJJJJ??7777!!!!!!!!!!!!!!!!!!!!!!!!!!!7777???JJJJYYYYYYJJ??7!~^:.                   //
//            ?5GGY?777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77?5YJP#5??^               //
//           YG!!JG5!!5J!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!JY7PY!5#Y!!7P!              //
//           B?!P57PG!!5Y!!J!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!?!YY?G?~P&??B&5?P              //
//          [email protected]@B!GP~![email protected][email protected]@@#?G              //
//          [email protected]@@5!&?!!5?!G7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!?7P!PJ~7&[email protected]@@GBJP              //
//           GJ!&@@&!GG~!?Y~5J!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!J7G!~5#7&@@&5PPY              //
//           [email protected]@@JJ#!!?Y~5?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!?P~!#[email protected]@@GPJB~              //
//           [email protected]@@P7&7~??!J!!!!!~!!!!!!~!!!~~~~!!!!!!!~~~!!!!!!!!!!!!!!!!!!!!!!7Y~7&[email protected]@@JPYG               //
//           ^#!?##@G!#?~!!7JJJJJ?YYY5J!?5PGG55P5JJJJYYYYYYYJJJJJ??7777?7!!!!!!!!~!~?#[email protected]@5??#~               //
//            [email protected]~GJ??YP7!^:~?PB#@@&@@@&#PYP#&BB#&BB&&B57^!!7??P#&#&@&BGGGGBGPY?JG~7&@5!5P                //
//            J&[email protected]!##Y?7..^~.    .^~~~~^:..:^!~  ..  ..          :!?JY?!^:.^~!?&@&[email protected]!?#:                //
//            .#P~J&&JBB .  ~77.  .^~~~~~:   ~JY5?                  !JY5^         [email protected]@P#@#!7#!                 //
//             [email protected]~?&&PY ^~       7PPGGP&G.              ^?JY55Y557 ~??7.         [email protected]@J#@?7B7                  //
//              7&J~7#&:  :JJ~     ..:. .                ~77??YYYJ~   ^!7:      ^:GB#P&P?B!                   //
//               7&J~JP. .P#@B       :!?J5PPGGGGGPP5J?.               ^?J:    :[email protected]~                    //
//                ~#57P7 J#?YP~^.    YPBB####&&@@&#@@#^        ^7JYYP5J.    ^~^  [email protected]@G7PY:                     //
//                 ^#55P7#@#7~Y#&P:   .:^~!!!7??^..:~: .       ~?JJJYYJ.   P##? :&@5YG!                       //
//                  :[email protected]&J7Y&B^                :YPGGGBJ             .^[email protected][email protected]:                        //
//                   [email protected]@YY5. .     ^JY5:     .7!!?J7~:^~~~~^:.   7B&@@GY&@&J5G.                         //
//                     ?#J~!5&@#PJ^!^    .~~^   .:^:      YPGBB#@@&G.  [email protected]@@5!5P.                          //
//                      ~#P!~Y&@#&@BY.         .J5P5.     .^~~~~!7~.   ^#J&[email protected]~5?                            //
//                       :[email protected]@@@JB~:~                   !JPG?    .^  ?BP&#J!5~                             //
//                         Y&??&@@@##: :~^:       .:^~!777!!~^.   !?~   .&@#7?Y^                              //
//                          7#[email protected]@#.  [email protected]&~      JPGBBBGB&###?  7&P#: !^@G!JJ.                               //
//                           ^BP!!Y&&!: #@@?     .:^~^7~.::..:: .GP~BY^?GP!5?                                 //
//                            .PB7~7GP7^B?PY^   ?YPGP:        7G&B!~5&YPY75!                                  //
//                              J#J~!YG#&7~PY.  ..... :!?^    [email protected]@[email protected]@B77P^                                   //
//                               !#[email protected]@&G5 :~       :~7:    [email protected]@&&##Y~?P:                                    //
//                                :[email protected]&@@?  ~?7.        [email protected]@PP?~J5.                                     //
//                                 .P&@@5#@#5Y&#@G       :&@@B5#@PP7~5Y.                                      //
//                                   5#@[email protected]@@B~JB^^~^  .^&@@&@@@P!!PJ                                        //
//                                   .7&[email protected]@@[email protected]:: [email protected]@@@@@J!P?                                         //
//                                     ~#[email protected]@@#?~~7&@P  [email protected]@@&B#7P7                                          //
//                                      :[email protected]@@@@P!?G&@: .#@&Y7JG!                                           //
//                                       .PG!BB?#@@[email protected]@~  Y&?~?G^                                            //
//                                         [email protected]@B#@@7  ?G~YP:                                             //
//                                          ?#[email protected]@@@@Y !Y555.                                              //
//                                           7#[email protected]@@@#?YPPY                                                //
//                                            ~BY~~Y&@@G7!?P7                                                 //
//                                             :[email protected]&7~JP~                                                  //
//                                               ?G?J#G!PY.                                                   //
//                                                ^Y5&#G7                                                     //
//                                                  7BG^                                                      //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Tasty is ERC721Creator {
    constructor() ERC721Creator("Pizza Pairatsu", "Tasty") {}
}