// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Onyro Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                 //
//                                                                                                                                                                           .75B#BGJ^                             //
//                                                                                                                                                                          !#@@[email protected]@@Y.                           //
//                                                                                                                                                                         [email protected]@&!   :[email protected]@G                           //
//                                                                                                                                                                        .#@@!      [email protected]@?                          //
//                                                                                                                                                                        [email protected]@#.      [email protected]@P                          //
//                :~7J5PGGGGGP5J7^.                :~7J5PGGGGGP5J7^.     :!~~:                      ~~~^        .~7J5PGGB?    :~?J5PGGGGGP5J7^.              :~7???7!^.   ^@@&.      [email protected]@5   .:~7???7!^.            //
//             ^[email protected]@@&#BGGGGGB#@@@&G?:          ^[email protected]@@&#BGPPPGB#@@@&P7.  :[email protected]@#:                    [email protected]@@!     :?G&@@&#BGPP! ^[email protected]@@&#BGGGGGB&@@@&G?.         [email protected]@@@@@@@@@[email protected]@J     ^&@@~:?G&@@@@@@@@@#5^          //
//           ^[email protected]@@P7^.        .:[email protected]@&J.      ^[email protected]@@P7^.        .:[email protected]@#J. :[email protected]@B:                  [email protected]@@7    .Y&@@G?^.     ^[email protected]@@P7^.        .:[email protected]@&J.      [email protected]@G7^:::^~?5#@@#5&@@5^.:7&@@[email protected]@&GJ!^:::^[email protected]@&^         //
//          [email protected]@@P^                 !#@@B:    7&@@P^                 !#@@B: :#@@B.                [email protected]@@?    ^#@@B~        [email protected]@@P:                 7&@@G:    .&@@!          [email protected]@#P&@@&@@@[email protected]@&?:          [email protected]@?         //
//         [email protected]@@Y                    ^&@@G   [email protected]@@5                    :#@@B. ^#@@G.              [email protected]@@Y    :#@@B.        [email protected]@@Y                    ^&@@G     [email protected]@&?:          [email protected]@?.!JYJ7^:&@@~          [email protected]@G.         //
//        .#@@#.                     [email protected]@@7 [email protected]@#.                     [email protected]@@J  ^&@@P             ^&@@5     [email protected]@@^        .#@@B                      [email protected]@@7     [email protected]@@GJ!^:::^~Y&@&~        [email protected]@G7^:::^~?5#@@#?.          //
//        [email protected]@@J                      :&@@G [email protected]@@Y                      .#@@B   ^&@@P           :#@@G     .&@@G         [email protected]@@J                      :&@@P       ^?G&@@@@@@@@@#P^         [email protected]@@@@@@@@@BY!.            //
//        [email protected]@@!                       #@@B [email protected]@@7                       [email protected]@&.   ~&@@5         [email protected]@B.     ^@@@5         [email protected]@@!                      .#@@B          .^~77?JPB####B5~   .?PB##&#B5?77!^.                //
//        [email protected]@@!                       #@@B [email protected]@@!                       [email protected]@&:    [email protected]@@Y        [email protected]@#:      ^@@@Y         [email protected]@@!                      .#@@B              :J#@@#G5P#@@5 ~#@@G5PB&@&P!                    //
//        [email protected]@@J                      :&@@G [email protected]@@!                       [email protected]@&:     [email protected]@@J      [email protected]@&^       ^@@@Y         [email protected]@@J                      :@@@P             J&@@5~.   .#@@[email protected]@J    :[email protected]@B^                  //
//        .#@@#.                     [email protected]@@7 [email protected]@@!                       [email protected]@&:      [email protected]@@?    [email protected]@@~        ^@@@Y         .#@@B                      [email protected]@@7            [email protected]@B^       [email protected]@[email protected]@?       [email protected]@@!                 //
//         [email protected]@@5                    ^&@@G  [email protected]@@!                       [email protected]@&:       [email protected]@@7  [email protected]@@7         ^@@@Y          [email protected]@@Y                    ^&@@G            [email protected]@G.       [email protected]@B [email protected]@&^       [email protected]@&^                //
//          [email protected]@@P^                 !#@@B:  [email protected]@@!                       [email protected]@&:        [email protected]@@[email protected]@@?          ^@@@Y           [email protected]@@P^                 7&@@G.           .#@@!      :[email protected]@B:  [email protected]@&?       [email protected]@J                //
//           ^[email protected]@@P?^.        .:[email protected]@&J.   [email protected]@@!                       [email protected]@&:         [email protected]@&&@@J           ^@@@Y            [email protected]@@P7^.        .:[email protected]@&J.             [email protected]@Y.  :[email protected]@&Y.    [email protected]@#J^.  ^#@@7                //
//             ^[email protected]@@@#BGGGGGB&@@@&G?:     [email protected]@@!                       [email protected]@@:          [email protected]@@@5            ^@@@5              ^[email protected]@@&#BGGGGGB&@@@&P7.               ^[email protected]@&B#@@@#J:        !P&@@&##@@&J                 //
//                :~7J5PGGGGPPYJ7^.        !PPP^                       ?PP5.          :&@@P             :PPP7                 :~7J5PGGGGPPYJ!^.                    ~J5PPY7^             :!J5PP57:                  //
//                                                                                   :[email protected]@G.                                                                                                                        //
//                                                                                  ~#@@P.                                                                                                                         //
//                                                                         :::::^[email protected]@&J                                                                                                                           //
//                                                                        .#@@@@@@@&GJ:                                                                                                                            //
//                                                                         ~!777!~^.                                                                                                                               //
//                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                 //
//        Anthony Kyriazis                                                                                                                                                                                         //
//        Onyro                                                                                                                                                                                                    //
//        Organic 3D Abstracts                                                                                                                                                                                     //
//        Twitter: @Onyro_Crypto                                                                                                                                                                                   //
//        Web: Onyro.com                                                                                                                                                                                           //
//                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Ony is ERC1155Creator {
    constructor() ERC1155Creator("Onyro Editions", "Ony") {}
}