// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Renaissance - by Haywyre & Aeforia
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                 !YJYY?^  ^YJJY7 7YJY! !YY^ .JJYJY!  7YY^  !YPPJ:   ~YPPJ^   7YJJYJ. ^YJYJ :YY7  ^J5PY!  ~YJYY!                 //
//                 [email protected]@#[email protected]@J [email protected]@@#Y [email protected]@@P [email protected]@! ^@@@@@5  [email protected]@7 [email protected]@B#@&^ [email protected]@B#@@!  [email protected]@@@&: [email protected]@@&[email protected]@P !&@@@@@Y [email protected]@&#J                 //
//                 [email protected]@? #@&[email protected]@G   [email protected]@@G [email protected]@! [email protected]@[email protected]  [email protected]@7.&@&[email protected]@Y [email protected]@^[email protected]@P  [email protected]@&: [email protected]@@&:^@@P [email protected]@J~&@# [email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected]@@B [email protected]@! [email protected]@[email protected]  [email protected]@7.&@#[email protected]@Y [email protected]@:[email protected]@G  [email protected][email protected]@^ [email protected]@@@^^@@P [email protected]@!.&@#[email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected]# [email protected]@! [email protected]@[email protected]  [email protected]@7.&@&[email protected]@Y [email protected]@^[email protected]@P .#@[email protected]@~ [email protected]&[email protected]!:&@P [email protected]@!.&@#[email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected]&[email protected]@! [email protected]@[email protected]  [email protected]@7.&@&[email protected]@Y [email protected]@^[email protected]@P .#@[email protected]@! [email protected]#[email protected]:&@P [email protected]@!.&@#[email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected]@:[email protected]@! [email protected]@[email protected]#. [email protected]@7.&@&[email protected]@Y [email protected]@^[email protected]@P :&@[email protected]@! [email protected]&[email protected]&@P [email protected]@!.&@#[email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected][email protected]^[email protected]@! [email protected]@[email protected]#. [email protected]@7.&@&[email protected]@Y [email protected]@^[email protected]@P :&@[email protected]@7 [email protected]&!&Y.&@P [email protected]@!.&@#[email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected]@[email protected]@! [email protected]@^[email protected]&: [email protected]@7.&@#[email protected]@Y [email protected]@:[email protected]@G ^&@[email protected]@? [email protected]&~&P.&@P [email protected]@7 ^^^ [email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected][email protected][email protected]@! [email protected]@^[email protected]&: [email protected]@7 #@&::77^ [email protected]@~.77~ [email protected]@[email protected]@J [email protected]&~#G.#@P [email protected]@7     [email protected]@5                   //
//                 [email protected]@5?&@5 [email protected]@G   [email protected][email protected][email protected]@! [email protected]&:[email protected]@^ [email protected]@7 [email protected]@G.    [email protected]@B:    [email protected]@J^@@Y [email protected]@^GB.#@P [email protected]@7     [email protected]@5                   //
//                 [email protected]@@@G?  [email protected]@&BY [email protected]^@[email protected]@! [email protected]&:[email protected]@~ [email protected]@7  [email protected]@B^    7&@#~   [email protected]@J^@@5 [email protected]@^P&:#@P [email protected]@7     [email protected]@&B?                 //
//                 [email protected]@G5&&5 [email protected]@#5? [email protected]:&[email protected]@! [email protected]&[email protected]@! [email protected]@7   !#@&!    ^[email protected]@?  [email protected]@?:&@P [email protected]@~5&:[email protected] [email protected]@7     [email protected]@B5!                 //
//                 [email protected]@? #@@:[email protected]@P   [email protected]#[email protected]@! [email protected]&[email protected]@! [email protected]@7    ^#@&^    [email protected]@! [email protected]@?:&@G [email protected]@[email protected]^[email protected] [email protected]@7     [email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected]#[email protected]@! [email protected]# [email protected]@7 [email protected]@7 Y5Y [email protected]@Y [email protected]@P [email protected]@7.&@G [email protected]@[email protected][email protected] [email protected]@7     [email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected]#.G#[email protected]@! #@#^[email protected]@? [email protected]@7.&@&[email protected]@Y #@@^[email protected]@G [email protected]@J~&@B [email protected]@[email protected]@P [email protected]@7 7?7 [email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected]#.5&!&@!.&@@@@@@J [email protected]@7.&@&[email protected]@Y [email protected]@^[email protected]@P [email protected]@@@@@# [email protected]@[email protected][email protected] [email protected]@!.&@&[email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected]&[email protected]!&@!.&@#[email protected]@Y [email protected]@7.&@&[email protected]@Y [email protected]@^[email protected]@P [email protected]@J~#@#[email protected]@7:@[email protected] [email protected]@!.&@#[email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected]&[email protected]&@!:&@B [email protected]@5 [email protected]@7.&@&[email protected]@Y [email protected]@^[email protected]@P [email protected]@~ #@&[email protected]@[email protected]@P [email protected]@!.&@#[email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected]&:[email protected]&@!^@@B [email protected]@P [email protected]@7.&@&[email protected]@Y [email protected]@^[email protected]@P [email protected]@~ [email protected]&:[email protected]@? #[email protected] [email protected]@!.&@#[email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G   [email protected]&:[email protected]@@@!^@@G [email protected]@G [email protected]@7.&@#[email protected]@Y [email protected]@:[email protected]@P [email protected]@^ [email protected]@^[email protected]@J [email protected]@@P [email protected]@!.&@#[email protected]@5                   //
//                 [email protected]@? #@&:[email protected]@G:. [email protected]&:^@@@@[email protected]@G [email protected]@G [email protected]@7 #@&:[email protected]@J [email protected]@[email protected]@5 [email protected]@^ [email protected]@^[email protected]@J [email protected]@@P [email protected]@?^&@# [email protected]@P..                 //
//                 [email protected]@J #@@:[email protected]@@@P [email protected]@^:&@@@[email protected]@G [email protected]@# [email protected]@7 ?&@&@@B: !&@&&@#^ #@@^ [email protected]@[email protected]@Y [email protected]@@P ^#@@&@&? [email protected]@@@Y                 //
//                 ^!!^ !!!..!!!7~ ~!!. !!!!::!!~ .!!! ^!!:  ^7J?!.   :7J?!.  !!!. ~!!::!!^ ^!!!~  .!?J7^  :!!!7^                 //
//                                                                                                                                //
//                 ..............................................................................................                 //
//                 ..............................................................................................                 //
//                                                                                                                                //
//                                                                                                                                //
//                    .!!!:   ^!!~     ~!!!!. ^!!!.    ~!!!!!~    ^!!!~    ^!!!!!~    .!!!:^!!!!!!!^   ^!!!!!!!!^                 //
//                    [email protected]@@^  [email protected]@5    [email protected]@@@@~ [email protected]@@?  [email protected]@G#@@G   ^&@@@B   ~&@&[email protected]@@^  :[email protected]@Y^&@@&#&@@@5 .#@@&#####~                 //
//                    [email protected]@5   [email protected]@@^   [email protected]@P&@@7 .#@@P :[email protected]@J [email protected]@5  :#@&@@G  ^#@&~^@@@J ~#@#! [email protected]@&: [email protected]@# [email protected]@&^    .                  //
//                   [email protected]@@?^^^[email protected]@P   [email protected]@5:#@@J  [email protected]@#7#@#~  [email protected]@5 :[email protected][email protected]@G [email protected]@!  [email protected]@[email protected]@G: .#@@5 .7&@&! [email protected]@G^^^^:                   //
//                   [email protected]@&#&&&@@@!  [email protected]@P  #@@5  ^&@@@@P.   [email protected]@[email protected]#:[email protected]@G [email protected]@7   [email protected]@@@@J   [email protected]@@&#&@#J: [email protected]@@&&&&&7                   //
//                  [email protected]@@7.:[email protected]@B  [email protected]@&J7?&@@G   [email protected]@@?     [email protected]@[email protected]#^ [email protected]@[email protected]@?    .#@@#~    [email protected]@[email protected]&#^ [email protected]@G:::::                    //
//                  [email protected]@B   :&@@7 [email protected]@#GBBB&@@B.  [email protected]@5      [email protected]@&@&^  [email protected]@&@@Y     ^&@@7    [email protected]@@~  [email protected]@&:^@@@!                         //
//                 ^@@@?   [email protected]@#[email protected]@G.    [email protected]@&: [email protected]@@~      [email protected]@@&~   [email protected]@@@5      [email protected]@#.    [email protected]@G   [email protected]@G [email protected]@@GPPPP?                    //
//                 ~YYJ.   ?YY!^YYJ.     !YYJ. 7YY?       !YJY~    :YYY?       ?YY!    .JYY~   JYY! JYYYYYYYY~                    //
//                                                        .::.                                                                    //
//                                                      !B#GGP.                            .!~                                    //
//                                                      #@7                                [email protected]                                    //
//                                                      [email protected]^                                .~^                                    //
//                     ^~!7!~^.         :~!7!~:     :^^^#@7^^:     .^!7!~:        ::  ^!7!  ::      .^!77!~:                      //
//                  .?BB5YJY5B#J     .?B#G555G#B7   !P5P&@P5PJ   ~P#BP55PB#Y:    :&#?PPYJJ [email protected]    :5#GYJJYP#B!                    //
//                  [email protected]       [email protected]   :[email protected]     :[email protected]     [email protected]^     [email protected]~     .7&&!   :&@G:     [email protected]   :#@7      :&&:                   //
//                  ~!.    .^[email protected]   [email protected]:^^^^^^::[email protected]     [email protected]^    [email protected]         ^@&:  :&&:      [email protected]   .~~    .:^!#@^                   //
//                   [email protected]  .&@G5PPPPPPP5PPY     [email protected]^    [email protected]?          [email protected]!  :&#.      [email protected]     :7Y5PGGP5&@^                   //
//                 .5&GJ!^:.  [email protected]  .#@7                 [email protected]^    [email protected]         .#@^  :&#.      [email protected]   ^G#5?!^.   #@^                   //
//                 [email protected]       ~&@?   [email protected]#:        7G7     [email protected]^    :#@!        [email protected]   :&#.      [email protected]   [email protected]!       [email protected]@^                   //
//                 ~&&?~^^[email protected]~^  7#&Y!^^^~?G&5:    .#@^     :P&G?~^^!JB&J    :@&.      [email protected]   [email protected]~^^[email protected]^:                 //
//                  :?5GGGP57. 75PY   .!YPGGGPY7:       JY:       ^?5PGGP57:     .YY.      :5J    ^JPGGGPY~ .JPP7                 //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HWxA is ERC721Creator {
    constructor() ERC721Creator("Renaissance - by Haywyre & Aeforia", "HWxA") {}
}